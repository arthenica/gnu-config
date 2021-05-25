#!/usr/bin/gawk -f
# -*- Awk -*-

# Automate (most of) the refactoring of config.guess to use an intermediate variable
# for uname-based results.

# GPLv3+

BEGIN {
    if (ARGC < 2) ARGV[ARGC++] = "config.guess"

    Indent = ""

    In_main_case = 0

    In_here_doc = 0
    Here_doc_end = ""

    If_depth = 0
    If_rewritten = 0
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

/^case \$UNAME_MACHINE:\$UNAME_SYSTEM/ { In_main_case = 1 }

function rewrite_echo_line(  i) {
    $2 = "GUESS="$2
    for (i=2; i<=NF; i++) {
	$(i-1)=$i
	if ($i == "#") {
	    $(i-2) = $(i-2)" "
	}
    }
    NF--
    $0 = Indent $0
}

# Track "if" depth within main case block
In_main_case && /^[[:space:]]+if / { If_depth++ }
In_main_case && /^[[:space:]]+fi/  { If_depth-- }

In_main_case && If_depth > 0 && /^[[:space:]]+echo/ {
    If_rewritten = 1
    rewrite_echo_line()
}

In_main_case && /^[[:space:]]+exit ;;$/ && If_rewritten {
    If_rewritten = 0
    print Indent";;"
    next
}

In_main_case && /^[[:space:]]+echo/ {
    getline next_line
    if (next_line !~ /^[[:space:]]+exit ;;/) {
	# not the output-and-exit we seek here...
	print
	print next_line
	next
    }

    if (/-cray-/ && $3 == "|") {
	# several Cray Unicos entries apply sed to the entire output in
	# order to edit the UNAME_RELEASE field; fix these up
	sub(/"\$UNAME_RELEASE"/, "\"$(echo &", $2)
	$NF = $NF")\""
    }

    rewrite_echo_line()
    if (next_line ~ /^[[:space:]]+exit ;;.+/)
	sub(/^[[:space:]]+exit ;;/, ";;     ", next_line)
    else
	sub(/^[[:space:]]+exit ;;/, ";;", next_line)
    print $0
    print Indent next_line
    next
}

In_main_case && /^esac/ {
    In_main_case = 0

    print # "esac"

    # Copy the rest of the input file
    while (getline) print
    nextfile
}

{ print }
