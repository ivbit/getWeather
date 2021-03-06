#!/usr/bin/dash

# Intellectual property information START
# 
# Copyright (c) 2021 Ivan Bityutskiy 
# 
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 
# Intellectual property information END

# Description START
#
# The script fetches weather data in form of json,
# filters it and pretty prints it through less.
# Dependencies: jq, gawk
#
# Description END

# Shell settings START
set -o noglob
# Shell settings END

# Declare variables START
url='192.168.10.44/json'
jsonResult="$(curl -s "$url")"
# Declare variables END

# BEGINNING OF SCRIPT
# If curl fails, print error message and exit
test $? -gt 0 && {
  echo '\n\033[38;2;150;0;0mThe weather website is temporarily unavailable.\033[0m\n'
  exit 1
}

# Parse json with jq, pipe it to gawk,
# pretty print the result into less.
echo "$jsonResult" |
  jq -M -r '(.main.temp, .main.pressure, .wind.speed, .wind.gust, .weather[].description, .clouds.all, .main.humidity, .sys.sunrise, .sys.sunset, .visibility)' |
  gawk 'NR == 1 {
  myTempC = int($1 - 273.15 + 0.5)
}
NR == 2 {
  myPressure = int($1 * 76000 / 101325 + 0.5)
}
NR == 3 {
  myWind = $1
}
NR == 4 {
  myGust = $1 !~ "null" ? $1 : 0
}
NR == 5 {
  gsub("rain","дождь",$0)
  gsub("show","снег",$0)
  gsub("light","Небольшой",$0)
  gsub("moderate","Умеренный",$0)
  gsub("heavy","Сильный",$0)
  gsub("intensity","ливневый",$0)
  gsub("clear sky","Ясно",$0)
  gsub("few clouds","Малооблачно",$0)
  gsub("scattered clouds","Переменная облачность",$0)
  gsub("broken clouds","Облачно с прояснениями",$0)
  gsub("overcast clouds","Пасмурно",$0)
  mySnowRain = $0
}
NR == 6 {
  myClouds = $1
}
NR == 7 {
  myHumidity = $1
}
NR == 8 {
  mySunrise = strftime("%d.%m.%Y %H:%M:%S", $1)
}
NR == 9 {
  mySunset = strftime("%d.%m.%Y %H:%M:%S", $1)
}
NR == 10 {
  myVisibility = $1 / 100
}

END {
  print "\n\033[38;2;0;120;0mПогода\033[0m"
  print "-----------------------------------"
  print "Температура:\t " myTempC " C"
  print "Давление:\t " myPressure
  print "Скорость ветра:\t " myWind " m/s"
  if (myGust)
  {
    print "Порывы:\t\t " myGust " m/s"
  }
  print "Осадки:\t\t " mySnowRain
  print "Небо закрыто на: " myClouds " %"
  print "Влажность:\t " myHumidity " %"
  if (myVisibility < 100)
  {
    print "Видимость:\t " myVisibility " %"
  }
  print "Восход:\t\t " mySunrise
  print "Закат:\t\t " mySunset
  print "-----------------------------------\n"
}' |
  less -R

# Shell settings START
set +o noglob
# Shell settings END

# END OF SCRIPT

