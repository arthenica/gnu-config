#!/usr/bin/gawk -f
# -*- Awk -*-

# Automate reversion of $( ) substitutions to classic `` form.

# GPLv3+

BEGIN {
    if (ARGC < 2) ARGV[ARGC++] = "config.guess"
}

# fix a special case of forgotten quotes
/\$\(\$dummy\)/ { sub(/\$\(\$dummy\)/, "$(\"$dummy\")") }

/\$\( \(/	{ $0 = gensub(/\$\( (\([^()]+\)[^()]*)\)/, "`\\1`", "g") }
/\$\(/		{ $0 = gensub(/\$\(([^()]+)\)/, "`\\1`", "g") }

/\$\( \(.*'/	{ $0 = gensub(/\$\( (\([^()]+'[^']+'[^()]*\)[^()]*)\)/, "`\\1`", "g") }
/\$\(.*'/	{ $0 = gensub(/\$\(([^()]+'[^']+'[^()]*)\)/, "`\\1`", "g") }

{ print }
