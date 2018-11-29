whatsapp2html V1.0 (c) Andrew C.R. Martin
=========================================

Installation
------------

Simply run the `install.sh` script to install locally. This will place
the script in `~/scripts/whatsapp2html` directory, an a link to an
executable in `~/bin`. Emojis and CSS will be placed in
`~/bin/share/whatsapp2html`.

Usage
-----

Go to the directory where you want to create the HTML version. e.g.

```
cd /home/httpd/html/whatsapp
```

and run the program with the name of the WhatsApp dump as a parameter. e.g.

```
whatsapp2html "~/whatsappdumps/WhatsApp Chat With xxx.txt"
```

Alternatively, you can specify the destination directory as a parameter:

```
whatsapp2html "WhatsApp Chat With xxx.txt" /home/httpd/html/whatsapp
```

The script will:

- copy all required emojis to the output directory
- copy the CSS to the output directory
- copy all required media files from the input directory to the output 
  directory
- generate an HTML file with the same name as the input file (but with 
  any spaces removed from the filename)

If the input and output are in the same directory then multimedia files 
will not be copied.


