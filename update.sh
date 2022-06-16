#!/bin/bash

yum -q -y update &&
    yum -q -y upgrade &&
    yum -q -y clean all