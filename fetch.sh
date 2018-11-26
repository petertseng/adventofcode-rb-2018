yes=

if [ "$1" = "--yes" ]; then
  yes=1
  shift
fi

day=$1

if [ $# -eq 0 ]; then
  day=$(TZ=UTC date +%-d)
  echo "OK, we have to guess the day, let's guess $day???"
else
  shift
  if [ "$1" = "--yes" ]; then
    yes=1
    shift
  fi
fi

daypad=$(seq -f %02g $day $day)

if [ "$yes" = "1" ]; then
  if [ -f input$day ]; then
    echo "THE INPUT ALREADY EXISTS!!!"
  else
    curl --cookie session=$(cat secrets/session) -o input$day https://adventofcode.com/2018/day/$day/input
  fi
else
  curl -o input$day http://example.com
fi

if [ -f $daypad.rb ]; then
  backup="$daypad-$(date +%s).rb"
  echo "I think we should back up $daypad.rb to $backup!"
  mv $daypad.rb $backup
fi

if [ -f TEMPLATE.rb ]; then
  cat TEMPLATE.rb input$day > $daypad.rb
elif [ -f t.rb ]; then
  cat t.rb input$day > $daypad.rb
fi
