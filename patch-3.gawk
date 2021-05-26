#!/usr/bin/gawk -f
# -*- Awk -*-

# Automate removing unneeded quotes in variable assignments and factoring
#  out some command substitutions in config.guess.

# GPLv3+

BEGIN {
    if (ARGC < 2) ARGV[ARGC++] = "config.guess"

    Indent = ""
    In_here_doc = 0
    Factor = "BOGUS!REL"
}

# Skip here documents
In_here_doc && $0 ~ /^[[:space:]]*EOF/ { In_here_doc = 0 }
In_here_doc { print; next }
/<</ { In_here_doc = 1 }
# Conveniently, all here documents in config.guess end with "EOF".

# Track indentation
/^[[:space:]]*/ {
    Indent_prev = Indent
    match($0, /^[[:space:]]*/)
    Indent = substr($0, RSTART, RLENGTH)
}

/^[[:space:]]+GUESS=/ {
    $0 = gensub(/GUESS="([^"[[:space:]]+)"$/, "GUESS=\\1", 1)
    $0 = gensub(/"(\$[[:alnum:]{}_]+)"([^[:alnum:]_]|$)/, "\\1\\2", "g")
    $0 = gensub(/"\$([[:alnum:]_]+)"([[:alnum:]_]|$)/, "${\\1}\\2", "g")
    if (/[[:space:]]#/) {
	$0 = gensub(/[[:space:]]#/, repeat("  ", gsub(/\$/, "&"))"&", 1)
    }

}

/\$\(echo \$[[:alnum:]_]+/ {
    # requote variables inside command substitutions
    $0 = gensub(/(\$\(echo )\$([[:alnum:]_]+)/, "\\1\"$\\2\"", "g")
}

# Factor out $(echo "$UNAME_RELEASE" | sed ...) into variables...
#  ... first, track what name to use:
/alpha:OSF1:/		{ Factor = "OSF"       }
/:SunOS:/		{ Factor = "SUN"       }
/:IRIX\*:/		{ Factor = "IRIX"      }
/CRAY[[:alnum:]*:-]+\)/	{ Factor = "CRAY"      }
/86:skyos:/		{ Factor = "SKYOS"     }
/:FreeBSD:/		{ Factor = "FREEBSD"   }
/:DragonFly:/		{ Factor = "DRAGONFLY" }
# The GNU system is a very special case and is handled manually.
/:GNU(\/\*)?:/ { Factor = "GNU" }

# ... second, split the GUESS= lines
/GUESS=/ && /\$\(echo[^|]+|.*sed/ && Factor != "GNU" {
    base = index($0, "\"$(")
    item = substr($0, base)
    tail = ""

    # special handling to clean up some FreeBSD cases
    if (Factor == "FREEBSD" && match($0, /-gnueabi/)) {

	# transfer the "-gnueabi" marker
	tail = substr($0, RSTART)
	$0 = substr($0, 1, RSTART-1); item = substr($0, base)

	# quote variable in inner substitution
	sub(/echo \${UNAME_RELEASE}/, "echo \"$UNAME_RELEASE\"", item)
	# remove unneeded braces
	if (sub(/\${UNAME_PROCESSOR}/, "$UNAME_PROCESSOR"))
	    base -= 2
    }

    # standardize spacing around pipe
    sub(/"\|sed/, "\" | sed", item)

    # remove quotes from command substitution
    sub(/^"/, "", item); sub(/"$/, "", item)

    print Indent Factor"_REL="item
    $0 = substr($0, 1, base-1)"$"Factor"_REL"tail
}

# Copy the rest of the file after the edits are done
/^[[:space:]]+echo "\$GUESS"/ {
    print
    while (getline) print
    nextfile
}

{ print }

function repeat(text, count,  ret) {
    for (ret = ""; count > 0; count--) ret = ret text
    return ret
}
