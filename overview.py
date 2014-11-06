#!/usr/bin/env python

from collections import OrderedDict
import itertools as it
from glob import glob


def loadYamlBlock(filename):
    with open(filename) as f:
        lines = it.takewhile(lambda l: not l.startswith('-'),
                             f.readlines()[1:])
    return {s[0]: ''.join(s[1:]).strip()
            for s in map(lambda x: x.split(':'), lines)}


def giveHtmlPath(mdPath):
    return mdPath.rstrip('.md') + '.html'


def loadInformation(folder):
    mdFiles = sorted(glob('{}/*.md'.format(folder)))
    return OrderedDict([(giveHtmlPath(f), loadYamlBlock(f)) for f in mdFiles])


def formatHtml(htmlPath, yamlInfo):
    datestring = ''
    if 'date' in yamlInfo:
        datestring = ' <small>Written on {}</small>'.format(yamlInfo['date'])
    return '''<dt><a href="{path}">{title}</a>{datestring}</dt>
    <dd>{description}</dd>'''.format(
        path=htmlPath,
        title=yamlInfo['title'],
        datestring=datestring,
        description=yamlInfo.get('description', '')
    )


def produceOverview(folder='posts'):
    allInfo = loadInformation(folder)
    return '\n'.join(reversed([formatHtml(path, info)
                               for path, info in allInfo.iteritems()]))


if __name__ == '__main__':
    print(produceOverview())
