
getemojis.pl
============

```
Usage: getemojis.pl [-force] [url]
       -force Download files even if they exist
```

Gets WhatsApp emojis as PNG files and rename them to their UNICODE names.

This is a utility program and not designed to be run by the end user.

- Create a directory called `emojis`

- cd to the `emojis` directory and run this program.

- use 

  `tar zcvf emojis.tgz emojis`

  to create a gzipped tar file of the emojis directory

- remove the `emojis` directory

- Place the `emojis.tgz` file in the root directory of the whatsapp2html
  software

By default, emojis will be obtained from $::emojiURL
