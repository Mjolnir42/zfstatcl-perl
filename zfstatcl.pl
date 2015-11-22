#!/usr/bin/env perl
# Copyright (c) 2015, Joerg Pernfuss <code+github@paranoidbsd.net>
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted providing that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
use strict;
use warnings;
use feature qw/ :5.20 /;
use autodie qw/ :default /;
BEGIN {
  use Cwd qw/ realpath /;
  use Getopt::Std;
  use IO::Socket::UNIX;
  use Scalar::Util qw/ looks_like_number /;

  use constant {
    EX_OK => 0,
    EX_ERROR => 1,
  };
  $| = 1;
}

my $empty = q|{"metrics":[]}|;
my $opts = {};
getopts('s:b:', $opts);
my $sock_path = realpath($opts->{s} // "/tmp/zfstatd.seqpacket");
my $buf_len = $opts->{b} // 65_536;
unless ( looks_like_number( $buf_len ) ) {
  say STDERR "Buffer length argument to -b must be a number";
  exit EX_ERROR;
}

my $client = IO::Socket::UNIX->new(
  Type => SOCK_SEQPACKET(),
  Peer => $sock_path,
);
# IO::Socket::UNIX does not trigger autodie
unless (defined $client) {
  say STDOUT $empty;
  exit EX_OK
}
$client->setsockopt(SOL_SOCKET, SO_RCVBUF, $buf_len);

# a single receive is OK since SEQPACKET is basically
# "datagrams over TCP", and the server only does a
# single write
my $data;
$client->recv($data, $buf_len);
$client->close;
say STDOUT $data;
exit EX_OK;
