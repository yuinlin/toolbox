# -*- coding: utf-8 -*-

import os
import fnmatch
import re
import urllib
import gc
import logging
import pandas as pd
import numpy as np


# CAUTION: This script can use a lot of memory.
# For 1 week of IIS logs, it uses ~17GB at peak.
# It will take ~15 minutes to complete for that amount of data.


def find_files(directory, pattern):
    for root, dirs, files in os.walk(directory):
        for basename in files:
            if fnmatch.fnmatch(basename, pattern):
                filename = os.path.join(root, basename)
                yield filename


def read_iis_log(fileName):
    return pd.read_csv(fileName, sep=' ',
                       header=0,
                       skiprows=4,
                       engine='c',
                       names=['date', 'time', 's-ip', 'cs-method', 'cs-uri-stem', 'cs-uri-query', 's-port',
                              'cs-username', 'c-ip', 'cs(User-Agent)', 'cs(Referer)', 'sc-status', 'sc-substatus',
                              'sc-win32-status', 'time-take', 'X-Forwarded-For', 'X-Forwarded-Proto'],
                       usecols=['date', 'time', 'cs-method', 'cs-uri-stem', 'cs-uri-query', 'sc-status', 'time-take'],
                       parse_dates={'datetime': ['date', 'time']},
                       infer_datetime_format=True)


id_subs = {
    re.compile(r'/parameter/\w+'): '/parameter/<id>',
    re.compile(r'/parameters/\w+'): '/parameters/<id>',
    re.compile(r'/attachments/trash/\w+$'): '/attachments/trash/<id>',
    re.compile(r'/attachments/\w+/download'): '/attachments/<id>/download',
    re.compile(r'/attachments/\w+$'): '/attachments/<id>',
    re.compile(r'/reporting/run/\w+'): '/reporting/run/<id>',
    re.compile(r'/reporting/details/\w+'): '/reporting/details/<id>',
    re.compile(r'/session/\w+'): '/session/<id>',
    re.compile(r';surrogates=(?:\d+,?)+'): ';surrogates=<id>',
    re.compile(r'/\w{32}/'): '/<id>/',
    re.compile(r'/\d+'): '/<id>'}


def remove_ids(uri_stem_series):
    for pattern, sub_text in id_subs.items():
        uri_stem_series = uri_stem_series.str.replace(pattern, sub_text)
    return uri_stem_series


def trim_trailing_slash(uri_series):
    return uri_series.str.replace(r'/$', '')


def get_cleaned_endpoint(uri_stem_series):
    return remove_ids(trim_trailing_slash(uri_stem_series.str.lower()))


static_params = [
    'getparts',
    'format',
    'publish',
    'applyrounding',
    'includenodedetails',
    'includeinvalidactivities',
    'n',
    'maxresults',
    'changeeventtype',
    'includegapmarkers']


queryfrom_param = 'queryfrom'
queryto_param = 'queryto'
max_days = 999999999


def get_datetime(date_value):
    date_string = str(date_value).upper()
    date_string_iso = re.sub(r'(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}-)(\d{2})(\d{2})', r'\1\2:\3', date_string)
    return pd.to_datetime(date_string_iso)


def get_time_range_days(qfrom, qto):
    try:
        if qfrom == 'mininstant' and qto == 'maxinstant':
            return max_days
        query_from_datetime = get_datetime(qfrom)
        query_to_datetime = get_datetime(qto)
        return (query_to_datetime - query_from_datetime).days
    except:
        # being bad and not handling the myriad possible time parsing errors
        return None


def get_query_time_range(param_string):
    params = urllib.parse.parse_qs(param_string)
    keys = list(params.keys())
    if queryfrom_param in keys:
        query_from = params[queryfrom_param][0]
        if queryto_param in keys:
            query_to = params[queryto_param][0]
        else:
            query_to = log_first_date
        return get_time_range_days(query_from, query_to)


def get_query_params(param_string):
    params = urllib.parse.parse_qs(param_string)
    keys = list(params.keys())
    for i in range(len(keys)):
        key = keys[i]
        if key in static_params:
            keys[i] = key + '=' + params[key][0]
    return '|'.join(sorted(keys))


delta_second_bin_breaks = [0, 1, 2, 3, 5, 8, 13, 30, 90, 300, 900, 3600, 14400, 86400, 604800]
delta_second_index = pd.IntervalIndex.from_breaks(delta_second_bin_breaks, closed='left')
delta_second_index_labels = [str(interval) for interval in delta_second_index]


def get_period_bin_counts(group):
    times = group['datetime']
    deltas = (times - times.shift(1)).dropna().map(pd.Timedelta.total_seconds)
    binned_deltas = pd.cut(deltas, delta_second_bin_breaks, right=False, labels=False)
    counts = pd.Series(binned_deltas.value_counts())
    zero_padding = pd.Series(data=0, index=range(len(delta_second_bin_breaks) - 1))
    return pd.DataFrame(counts + zero_padding).T


delta_day_bin_breaks = [1, 92, 183, 365, 548, 730, 913, 1095, 1825, 3650, 36500, 365000, max_days]
delta_day_index = pd.IntervalIndex.from_breaks(delta_day_bin_breaks)
delta_day_index_labels = [str(day) for day in delta_day_index]


def get_query_time_range_bin_counts(group):
    binned_deltas = pd.cut(group['query_time_range'], delta_day_bin_breaks, labels=False)
    counts = pd.Series(binned_deltas.value_counts())
    zero_padding = pd.Series(data=0, index=range(len(delta_day_bin_breaks) - 1))
    return pd.DataFrame(counts + zero_padding).T


logging.basicConfig(level=logging.DEBUG)
log_dir_root = input('Enter root folder containing IIS logs (can be in nested folders): ')
log_dir_root = re.sub('\\$', '', log_dir_root) + '\\'
file_names = [f for f in find_files(log_dir_root, 'u_ex*')]
files = (read_iis_log(f) for f in file_names)
df = pd.concat(files, sort=False)
gc.collect()

df.sort_values(by=['datetime'], inplace=True)
log_first_date = df['datetime'][0]

df['endpoint'] = get_cleaned_endpoint(df['cs-uri-stem'])
df.drop(columns=['cs-uri-stem'], inplace=True)
gc.collect()

exclude_uris = ['/resource/',
                '/resources$',
                '/static/',
                'swagger',
                '/metadata$',
                '/help/',
                '/help-en/',
                '/dist/',
                '/styles/',
                '/scripts/',
                '/images/',
                '/localization/',
                '/docs/',
                '/icons/',
                'favicon',
                '\.\w{2,5}$']
exclude_uri_re = '|'.join(exclude_uris)
df = df[~df['endpoint'].str.contains(exclude_uri_re)]
gc.collect()

df['query_time_range'] = df['cs-uri-query'].str.lower().apply(get_query_time_range)
df['param_names'] = df['cs-uri-query'].str.lower().apply(get_query_params)
df.drop(columns=['cs-uri-query'], inplace=True)
gc.collect()
group_columns = ['endpoint', 'cs-method', 'sc-status', 'param_names']
by_query = df.groupby(group_columns)

period_bin_counts = by_query.apply(get_period_bin_counts).reset_index(level=4).drop(columns=['level_4'])
query_time_range_bin_counts = by_query.apply(get_query_time_range_bin_counts).reset_index(level=4).drop(columns=['level_4'])
time_stats = pd.pivot_table(df, values=['time-take'], index=group_columns, aggfunc=[np.mean, np.sum, len])
time_stats.columns = ['mean_time_ms', 'sum_time_ms', 'count']

output = time_stats.join(period_bin_counts).join(query_time_range_bin_counts, rsuffix='_q')
column_map = dict([(str(i), delta_second_index_labels[i] + ' s') for i in range(len(delta_second_index_labels))] +
                  [(str(i) + '_q', delta_day_index_labels[i] + ' d') for i in range(len(delta_day_index_labels))])
output = output.rename(index=str, columns=column_map)

output_csv = output.to_csv()
with open(log_dir_root + r'output.csv', 'w') as f:
    f.write(output_csv)
