#!/usr/bin/perl
use strict;
my $prevDate = '';
my $prevName = '';
my $person   = 0;

PrintHTMLHeader();

open my $fp, "<:encoding(UTF-8)", $ARGV[0] or die;

while(<$fp>)
{
    chomp;

    # 01/01/2018, 10:00 - Name name: text
    if(/(\d.*?),\s+(\d\d:\d\d)\s+-\s+(.*?):\s+(.*)/)
    {
        my $date = $1;
        my $time = $2;
        my $name = $3;
        my $text = $4;

        if($date ne $prevDate)
        {
            PrintDate($date);
            $prevDate = $date;
        }
        if($name ne $prevName)
        {
            $person = $person?0:1;
            $prevName = $name;
            ClearBoth();
        }

        PrintMessage($person, $name, $time, $text);
    }
    elsif(! /^\d+\/\d+\/\d+/)
    {
        my $text = $_;
        PrintMessage($person, '', '', $text);
    }
}

PrintHTMLFooter();

sub PrintDate
{
    my($date) = @_;

    ClearBoth();
    print <<__EOF;
<div class='datewrap'>
  <div class='date'>$date</div>
</div>
__EOF
    ClearBoth();
}

sub PrintMessage
{
    my($person, $name, $time, $text) = @_;
    $text = FixImageLink($text);
    $text = EmojifyText($text);
    if($name ne '')
    {
        print "<div class='person person$person'>\n";
        print "  <p class='msghead'>$name: $time</p>\n";
        print "  <p class='msgbody'>$text</p>\n";
        print "</div> <!-- person person$person --> \n";
    }
    else
    {
        print "<div class='person person$person'>\n";
        print "  <p class='msgbody'>$text</p>\n";
        print "</div> <!-- person person$person --> \n";
    }
        
}

sub EmojifyText
{
    my($text) = @_;
#    $text = decode_utf8 $text;
    if($text =~ /(\N{U+1F600})/)
    {
        $text =~ s/$1/{X}/;
    }
    return($text);
}

sub PrintHTMLHeader
{
    print <<__EOF;

<html>
<head>
<title>WhatsApp Chat</title>
<link rel='stylesheet' type='text/css' href='whatsapp.css' />
</head>
<body>
<div class='whatsapp'>

__EOF

}

sub PrintHTMLFooter
{
    print <<__EOF;

</div> <!-- whatsapp -->
</body>
</html>

__EOF

}

sub ClearBoth
{
    print "<div style='clear: both;'>&nbsp;</div>\n";
}

sub FixImageLink
{
    my($text) = @_;

    if($text =~ /(IMG.*)\s+\(file attached\)/)
    {
        my $img = $1;
        $text =~ s/\s+\(file attached\)//;
        $text =~ s/$img/<a href='$img'><img src='$img' alt='$img' width='400px' \/><\/a>/;
    }

    return($text);
}
