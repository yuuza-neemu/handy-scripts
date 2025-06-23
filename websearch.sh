#!/bin/bash
# A script to call rofi and select from a defined set of websites, shortcuts (like bangs in DDG)
# and open them in a browser. This is used to quickly navigate to different websites

# To be implemented: defining a shortcut - website list in a file, and parse this to find the 
# website someone wants to visit. This way you can use bookmarks independently from a browser

options="w Wikipedia\nwd Wikipedia Deutsch\naw ArchWiki\ndi Dict.cc\ny YouTube\na Address\n"

selected=$(echo -e "$options" | rofi -dmenu -p "Select search/bookmark:")

# Extract prefix which is first string
prefix=$(awk '{print $1}' <<< "$selected")

# Parse prefix and query
query=$(awk '{print $2}' <<< "$selected")


# URL encode the query
# Important for sanitizing string for websearch
# as a URL cannot contain certain characters
# Also trims trailing new lines
urlencode() {
      printf '%s' "$1" | jq -sRr @uri
}

case "$prefix" in
    # Address input
    a)
        url="https://$query"
        ;;
    # Short cuts for searches
    w)
        url="https://en.wikipedia.org/wiki/Special:Search?search=$(urlencode "$query")"
        ;;
    aw)
        url="https://wiki.archlinux.org/index.php?search=$(urlencode "$query")"
        ;;
    wd)
        url="https://de.wikipedia.org/wiki/Special:Search?search=$(urlencode "$query")"
        ;;
    di)
        url="https://www.dict.cc/?s=$(urlencode "$query")"
        ;;
    y)
        url="https://www.youtube.com/results?search_query=$(urlencode "$query")"
        ;;
    # Default: Search Engine
    # If not standard case, we the query is stored in the prefix
    *)
        url="https://duckduckgo.com/?t=ffab&q=$(urlencode "$prefix")&ia=web"
        ;;
esac

xdg-open "$url"

