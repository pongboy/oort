require 'tty.write'

function init()
  -- Enable tty
  send_message(env.shell, { tty = true })

  write_line("Type the name of the app you want to")
  write_line("start after the \"~\" prompt")

  write_line("")

  write_line("For extra help, check out:")
  write_line("") 
  write_line("https://github.com/pongboy/nibble/", 2)
  write_line("")

  write("You can type ")
  write("ls apps", 8)
  write_line(" to list available apps!")

  stop_app(0)
end


