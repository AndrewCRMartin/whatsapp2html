#!/usr/bin/perl
use strict;
my $emojiURL = "https://emojipedia.org/whatsapp/2.17/";
if(scalar(@ARGV))
{
    my $val = shift @ARGV;
    if($val eq "-h")
    { 
        UsageDie();
    }
    else
    {
        $emojiURL = $val;
    }
}

my $exe = '';

print STDERR ">>>> Grabbing index of emojis from $emojiURL\n\n";
$exe = "wget $emojiURL";
`$exe`;
print STSERR ">>>> done\n\n";

print STDERR ">>>> Grabbing emojis\n\n";

my $fileName = GetFilename($emojiURL);
if(open(my $fp, '<', "$fileName"))
{
    while(<$fp>)
    {
        chomp;
        if(/\<img/)
        {
            if(/ data-src\s*?=\s*?"(.*?)"/)
            {
                $exe = "wget $1";
                `$exe`;
            }
            elsif(/ src\s*?=\s*?"(.*?)"/)
            {
                $exe = "wget $1";
                `$exe`;
            }
        }
    }
    close $fp;
    unlink $fileName;
}
else
{
    print STDERR ">>>Unable to download and open $fileName\n";
}

print STSERR ">>>> done\n\n";

sub UsageDie
{
    print <<__EOF;

getemojis.pl

Usage: getemojis.pl [url]

Gets WhatsApp emojis as PNG files.

__EOF

}

sub GetFilename
{
    my($url) = @_;
    my $fnm = 'index.html';

    $url =~ s/.*\///; # Remove path
    if($url =~ /\./)
    {
        $fnm = $url;
    }
    return($fnm);
}
