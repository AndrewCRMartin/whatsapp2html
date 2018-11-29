#!/usr/bin/perl
use strict;
$::emojiURL = "https://emojipedia.org/whatsapp/2.17/";
if(scalar(@ARGV))
{
    my $val = shift @ARGV;
    if($val eq "-h")
    { 
        UsageDie();
    }
    else
    {
        $::emojiURL = $val;
    }
}

GrabEmojis($::emojiURL);
FixUpEmojis();

sub FixUpEmojis
{
    opendir my $dfh, "." || die;

    my @files = readdir $dfh;
    foreach my $file (@files)
    {
        if($file =~ /.*_(.*?)\.png/)
        {
            my $unicode = $1;
            my $link = "$unicode.png";
            if((! -e $link) || $::force)
            {
                my $exe = `mv $file $link`;
                `$exe`;
            }
            else
            {
                unlink $file;
            }
        }
    }
}

sub GrabEmojis
{
    my($emojiURL) = @_;
    my $exe = '';

    # First grab the list of emojis
    print STDERR ">>>> Grabbing index of emojis from $emojiURL\n\n";
    $exe = "wget $emojiURL";
    `$exe`;
    print STSERR ">>>> done\n\n";
    my $fileName = GetFilename($emojiURL);
    
    # Now grab the actual emojis
    print STDERR ">>>> Grabbing emojis\n\n";
    if(open(my $fp, '<', "$fileName"))
    {
        while(<$fp>)
        {
            chomp;
            if(/\<img/)
            {
                if(/ data-src\s*?=\s*?"(.*?)"/)
                {
                    my $url = $1;
                    if((! -e $url) || defined($::force))
                    {
                        $exe = "wget $1";
                        `$exe`;
                    }
                }
                elsif(/ src\s*?=\s*?"(.*?)"/)
                {
                    my $url = $1;
                    if((! -e $url) || defined($::force))
                    {
                        $exe = "wget $1";
                        `$exe`;
                    }
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

sub UsageDie
{
    print <<__EOF;

getemojis.pl

Usage: getemojis.pl [-force] [url]
       -force Download files even if they exist

Gets WhatsApp emojis as PNG files and rename them to their UNICODE names.

This is a utility program and not designed to be run by the end user.
- Create a directory called 'emojis'
- cd to the 'emojis' directory and run this program.
- use 
  'tar zcvf emojis.tgz emojis'
  to create a gzipped tar file of the emojis directory
- remove the 'emojis' directory
- Place the 'emojis.tgz' file in the root directory of the whatsapp2html
  software

By default, emojis will be obtained from $::emojiURL

__EOF

    exit 0;
}

