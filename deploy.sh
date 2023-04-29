#!/bin/bash

set -ex

zola build
rsync -avz -e ssh ./public/ uberspace:./html/
