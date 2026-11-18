#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 16;
use HTML::Defang;

use strict;
use warnings;

my ($D, $R);

#################################
#  url_policy => 'mail'
#################################

$D = HTML::Defang->new(url_policy => 'mail', delete_defang_content => 1);

$R = $D->defang(<<'EOF');
1:<a href="http://example.com/">http</a>
2:<a href="mailto:a@example.com">mailto</a>
3:<a href="#top">anchor</a>
4:<a href="javascript:alert(1)">js</a>
5:<a href="java&#x09;script:alert(1)">js entity</a>
6:<a href="page.html">relative</a>
7:<img src="cid:part1@example.com">
8:<img src="data:image/png;base64,AAAA">
9:<img src="data:image/svg+xml;base64,AAAA">
10:<img src="https://example.com/i.png">
11:<img src="mailto:a@example.com">
12:<table background="cid:bg@example.com">
13:<p style="background: url(cid:bg@example.com)">
14:<p style="background: url(javascript:alert(1))">
15:<p style="background: url(http://example.com/a.png), url(file:///etc/passwd)">
EOF

like($R, qr{1:<a href="http://example.com/">}, "http link kept");
like($R, qr{2:<a href="mailto:a\@example.com">}, "mailto link kept");
like($R, qr{3:<a href="#top">}, "anchor link kept");
like($R, qr{4:<a >}, "javascript link removed");
like($R, qr{5:<a >}, "entity obfuscated javascript link removed");
like($R, qr{6:<a >}, "relative link removed");
like($R, qr{7:<img src="cid:part1\@example.com">}, "cid image kept");
like($R, qr{8:<img src="data:image/png;base64,AAAA">}, "inline png kept");
like($R, qr{9:<img >}, "inline svg removed");
like($R, qr{10:<img src="https://example.com/i.png">}, "https image kept");
like($R, qr{11:<img >}, "mailto image removed");
like($R, qr{12:<table background="cid:bg\@example.com">}, "cid table background kept");
like($R, qr{13:<p style="background: url\(cid:bg\@example.com\)">}, "cid CSS url kept");
like($R, qr{14:<p style="">}, "javascript CSS url removed");
like($R, qr{15:<p style="">}, "file CSS url after a good one removed");

ok(!eval { HTML::Defang->new(url_policy => 'nope'); 1 }, "Unknown url_policy dies");
