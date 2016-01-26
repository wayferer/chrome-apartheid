#!/bin/bash

# cdi.sh - Make chrome profiles behave like multiple browsers on Mac OS X
#          (Tested on Yoshmite). Make profiles work like seperate applications
#          - esp. useful if you want to easily switch between different browsers
#          in different virtual desktops / workspaces, or don't want work
#          windows mixed in with home windows in the "Window" menu, or want to
#          be able to easily see what processes are with a certain profile in
#          chrome task manager, or be able to eaisly quit one profile with
#          multiple windows open and start where you left of later.

set -e

cd /Users/$USER/Library/Application\ Support/Google/Chrome

CDI="cdi-chrome.d"
APPLESCRIPTS="$CDI/Applescript-Sources"
LAUNCHERS="$CDI/Chrome-Launchers"
RUNTIMES="$CDI/Chrome-Runtimes"
test -d $CDI || mkdir $CDI
test -d $APPLESCRIPTS || mkdir $APPLESCRIPTS
test -d $LAUNCHERS || mkdir $LAUNCHERS
test -d $RUNTIMES || mkdir $RUNTIMES

ls Profile 1/Preferences Profile*/Preferences | sed s:/Preferences::g > profiles.tmp
while read PROFILE; do
  echo "$PROFILE;\c";
  cd "$PROFILE"
  ruby -rjson -e 'j = JSON.parse(File.read("Preferences")); puts j["profile"]["name"]' | sed 's:\@:-at-:g' | sed 's/;\ /;/g' | sed 's:\ ::g' | sed 's/^/"/g' | sed 's/$/"/g'
  cd ..
done < profiles.tmp > $CDI/profiles.txt
# Like: Profile 1;"webmaster-at-example.org"

echo "Be patient, this involves copying a lot of data..."

while read PROFILE; do

  DIR="$(echo $PROFILE | awk -F\; '{print $1}')"
  # Like: DIR='Profile 1'
  echo "Working on profile: $DIR"

  LINK="$(echo $PROFILE | awk -F\; '{print $2}' | sed 's/\ /\-/g' | sed 's/"//g' | sed 's/^/cdi-profile-/g')"
  # Like: cdi-profile-webmaster-at-example.org

  APP="$(echo $LINK | sed 's/^cdi-profile-//g' | sed 's/$/\.app/g')"
  # Like: webmaster-at-example.org.app

  ICONQ="$(echo -e 'Icon\015')"
  #ICON="$(echo -e 'Icon\015')/..namedfork/rsrc"
  # This is the resource fork of the Icon? file - you can cat / redirect but not cp

  SHIM="$(echo $LINK | sed 's/^cdi-profile-//g' | sed 's/$/\.app/g')"
  # Like: webmaster-at-example.org.app

  TXT="$APPLESCRIPTS/$(echo $LINK | sed 's:^cdi-profile-:chrome-:g' | sed 's/$/\.txt/g')"
  # Like:
  # cdi-chrome.d
  # /Applescript-Sources/chrome-webmaster-at-example.org.txt

  test -L "$LINK" || ln -s "$DIR" "$LINK"
  cd "$LINK"
  test -L Default || ln -s . Default
  cd /Users/$USER/Library/Application\ Support/Google/Chrome
  test -f "$RUNTIMES/$APP/$ICONQ" && cp "$RUNTIMES/$APP/$ICONQ" "$RUNTIMES/${APP}.icon"
  test -d "$RUNTIMES/$APP" && rm -rf "$RUNTIMES/$APP"
  cp -R /Applications/Google\ Chrome.app "$RUNTIMES/$APP"
  test -f "$RUNTIMES/${APP}.icon" && cp "$RUNTIMES/${APP}.icon" "$RUNTIMES/$APP/$ICONQ"
  SetFile -a C "$RUNTIMES/$APP"

  ## This section disabled because enabling it makes automatic profile login not work.
  ## There is a chance someone who knows more about chrome will help at some point; see:
  ## https://code.google.com/p/chromium/issues/detail?id=460787
  ## https://groups.google.com/a/chromium.org/forum/#!topic/chromium-discuss/0HEeMuh8WqA
  ## https://github.com/lhl/chrome-ssb-osx
  # Change Bundle ID so desktop assignation works. Not sure if this will survive updates.
  # CFBundleIdentifier must contain only alphanumeric (A-Z,a-z,0-9), hyphen (-), and period (.) characters.
  # (Based on fiddling around there also seems to be a length limit.)
  #UUID="$(echo $APP | md5sum | awk '{print $1}' | tr [0-9] [A-Z] | cut -c 1-4,29-32)"
  #plutil -replace CFBundleIdentifier -string "cdi.$UUID" -- "$RUNTIMES/$APP/Contents/Info.plist"
  #plutil -replace CFBundleName -string "$UUID" -- "$RUNTIMES/$APP/Contents/Info.plist"
  #plutil -replace CFBundleDisplayName -string "$UUID" -- "$RUNTIMES/$APP/Contents/Info.plist"
  #plutil -replace KSProductID -string "cdi.$UUID" -- "$RUNTIMES/$APP/Contents/Info.plist"
  # To check: defaults read ~/Library/Preferences/com.apple.spaces.plist app-bindings

  echo "on run" > $TXT
  echo "do shell script \c" >> $TXT
  echo '"/Users/'$USER'/Library/Application\\\\ Support/Google/Chrome/'$RUNTIMES'/'$APP'/Contents/MacOS/Google\\\\ Chrome --user-data-dir=/Users/'$USER'/Library/Application\\\\ Support/Google/Chrome/'$LINK'  > /dev/null 2>&1 &"' >> $TXT
  echo "quit" >> $TXT
  echo "end run" >> $TXT
  test -d "$LAUNCHERS/$SHIM" || osacompile -o "$LAUNCHERS/$SHIM" $TXT

done < $CDI/profiles.txt

echo
echo 'Done with automated portion. Now you should manually:'
echo
echo '1. Add (identical) icons of your choice to each pair of profile Launchers'
echo '   / Runtimes in the folder ~/Library/Application Support/Google/Chrome/'
echo '   cdi-chrome.d'
echo '   (google for numerous guides on how to change mac os x app icons)'
echo
echo '2. From the finder, drag the "Chrome-Launchers" folder to the stacks area'
echo '   of the dock. Right click on the stack and select "List" for easy viewing.'
echo '   Also select "Display as Folder" and give the folder a nice icon.'
echo
echo '3. BE SURE to only open Chrome via this stack. DO NOT pin the app-area'
echo '   Chrome icon(s) to the app area of the dock! DO NOT run "normal" Chrome!'
echo
echo 'The only exception to (3) is if you need to add a new profile. In that case,'
echo 'close all instances, then open the "normal" Chrome, add profile, close, and'
echo 'then run this script again.'
echo
echo 'Note: when you launch first time you will get "Welcome to Google Chrome"'
echo '      dialog box. This is normal; do not worry. It will ask if you want'
echo '      to set Chrome as default; this applies to that instance of chrome.'
echo '      Choosy - http://www.choosyosx.com/ - works great with this!'
echo
