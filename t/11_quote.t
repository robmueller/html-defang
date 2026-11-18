#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 23;
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

#################################
#  extract_styles
#################################

$D = HTML::Defang->new(extract_styles => 1, delete_defang_content => 1);

$R = $D->defang(<<'EOF');
<style>p { color: red }</style><p>Text</p>
<style media="print">p { color: black }</style>
<style>q { color: blue } </div> { x: y }</style>
<style></style>
EOF

unlike($R, qr{<style|</style}i, "Style tags removed from output");
like($R, qr{<p>Text</p>}, "Content kept");
like($D->extracted_styles, qr{^p \{ color: red \}\n}, "First style extracted");
like($D->extracted_styles, qr{\@media print \{\np \{ color: black \}\n\}}, "media attribute becomes an \@media block");
unlike($D->extracted_styles, qr{</}, "Nothing in extracted styles can close a style element");

$D->defang('<p>No styles</p>');
is($D->extracted_styles, '', "Extracted styles reset on each call");

$R = HTML::Defang->new(extract_styles => 1)->defang('<style>p { color: red }</style>');
is($R, '', "Style tags removed without delete_defang_content too");
