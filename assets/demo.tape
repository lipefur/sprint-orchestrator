# VHS tape — animated demo of the sprint dispatch flow.
#
# Render to assets/demo.gif (one command, fully headless, nothing real captured):
#   brew install vhs        # https://github.com/charmbracelet/vhs
#   vhs assets/demo.tape
#
# Then embed at the top of the "A ideia" section in the READMEs:
#   ![Sprint dispatch demo](assets/demo.gif)

Output assets/demo.gif

Set Shell "bash"
Set FontSize 18
Set Width 1100
Set Height 560
Set Theme "Dracula"
Set Padding 24
Set TypingSpeed 40ms

Sleep 800ms
Type "# Sprint 1 is planned & committed to main. Now dispatch it:"
Sleep 400ms
Enter
Sleep 600ms
Type "bash assets/demo-mock.sh"
Sleep 500ms
Enter
Sleep 5s
