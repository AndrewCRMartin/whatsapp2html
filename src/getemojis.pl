#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    getemojis
#   File:       getemojis.pl
#   
#   Version:    V1.0
#   Date:       04.12.18
#   Function:   Download WhatsApp Emojis and rename the files such that
#               they are just named by the Unicode combinations
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, 2018
#   Author:     Dr. Andrew C. R. Martin
#   EMail:      andrew@andrew-martin.org
#               
#*************************************************************************
#
#   This program is not in the public domain, but it may be copied
#   according to the conditions laid out in the accompanying file
#   COPYING.DOC
#
#   The code may be modified as required, but any modifications must be
#   documented so that the person responsible can be identified. If 
#   someone else breaks this code, I don't want to be blamed for code 
#   that does not work! 
#
#   The code may not be sold commercially or included as part of a 
#   commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#   Description:
#   ============
#
#   Utility program for use with whatsapp2html that grabs the set of
#   WhatsApp emojis from emojipedia
#
#*************************************************************************
#
#   Usage:
#   ======
#
#   mkdir emojis
#   cd emojis
#   getemojis.pl [-n][-force] [url]
#   cd ..
#   tar zcvf emojis.tgz emojis
#   rm -rf emojis
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   04.12.18  Original
#
#*************************************************************************
use strict;

UsageDie() if defined($::h);

$::emojiURL = "https://emojipedia.org/whatsapp/2.17/";
if(scalar(@ARGV))
{
    my $val = shift @ARGV;
    $::emojiURL = $val;
}

GrabEmojis($::emojiURL) if(!defined($::r));
FixUpEmojis() if(!defined ($::n));


#*************************************************************************
# void FixUpEmojis(void)
# ----------------------
# Rename all emojis in the current directory with .png extension based
# on their unicode info alone
#
# 04.12.18  Original   By: ACRM
sub FixUpEmojis
{
    opendir my $dfh, "." || die;

    my @files = readdir $dfh;
    foreach my $file (@files)
    {
        my $unicode = '';
        if($file =~ /modifier-fitzpatrick/)
        {
            if($file =~ /.*modifier.*_(.*)_.*\.png/)
            {
                # The Fitzpatrick modifier emojis have a name with
                # xxxx_unicode-unicode[-unicode...]_unicode.png
                # The part that we want is between TWO underscores
                $unicode = $1;
            }
            elsif($file =~ /.*modifier.*_(.*)\.png/)
            {
                # The exception is just colour swatches where there is only
                # one underscore
                $unicode = $1;
            }
        }
        else
        {
            if($file =~ /.*_(.*?)\.png/)
            {
                $unicode = $1;
            }
        }

        if($unicode ne '')
        {
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


#*************************************************************************
# GrabEmojis($emojiURL)
# ---------------------
# \param[in]    $emojiURL   URL for the set of emojis
#
# From the provided URL, obtains the file (or index file) and extracts 
# the list of emojis. Then grabs each of these in turn.
#
# Uses wget to do this.
#
# 04.12.18  Original   By: ACRM
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


#*************************************************************************
# $fnm = GetFilename($url)
# ------------------------
# \param[in]    $url      A URL
# \return                 The filename part of the URL
#
# Obtains the resulting filename from the URL - if the URL is a complete
# path containing a filename at the end then this will be returned.
# Otherwise, (if no filename appears in the URL) it returns index.html
#
# 04.12.18  Original   By: ACRM
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


#*************************************************************************
# void UsageDie(void)
# -------------------
# Prints a usage message and exits
#
# 04.12.18  Original   By: ACRM
sub UsageDie
{
    print <<__EOF;

getemojis.pl V1.0 (c) 2018 Dr. Andrew C.R. Martin

Usage: getemojis.pl [-n][-force] [url]
       -n     Do not rename the files
       -r     Only rename the files
       -force Download and rename files even if they exist

Gets WhatsApp emojis as PNG files and rename them to their UNICODE names.

This is a utility program and not designed to be run by the end user.
- Create a directory called 'emojis'
- cd to the 'emojis' directory and run this program.
- use 
  'tar zcvf emojis.tgz emojis'
  to create a gzipped tar file of the emojis directory
- remove the 'emojis' directory
- Place the 'emojis.tgz' file in the root directory of the whatsapp2html
  software distribution directory

By default, emojis will be obtained from $::emojiURL

__EOF

    exit 0;
}

