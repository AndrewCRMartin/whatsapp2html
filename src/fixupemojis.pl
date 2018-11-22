#!/usr/bin/perl

opendir my $dfh, "." || die;

my @files = readdir $dfh;
foreach my $file (@files)
{
    if($file =~ /.*_(.*?)\.png/)
    {
        my $unicode = $1;
        my $link = "$unicode.png";
        if(! -e $link)
        {
            my $exe = `ln -s $file $link`;
            `$exe`;
        }
    }
}
