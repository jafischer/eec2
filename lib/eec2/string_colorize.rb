class String
  def black;          $stdout.isatty ? "\e[30m#{self}\e[0m" : self end
  def red;            $stdout.isatty ? "\e[31m#{self}\e[0m" : self end
  def green;          $stdout.isatty ? "\e[32m#{self}\e[0m" : self end
  def brown;          $stdout.isatty ? "\e[33m#{self}\e[0m" : self end
  def blue;           $stdout.isatty ? "\e[34m#{self}\e[0m" : self end
  def magenta;        $stdout.isatty ? "\e[35m#{self}\e[0m" : self end
  def cyan;           $stdout.isatty ? "\e[36m#{self}\e[0m" : self end
  def gray;           $stdout.isatty ? "\e[37m#{self}\e[0m" : self end
  def bg_black;       $stdout.isatty ? "\e[40m#{self}\e[0m" : self end
  def bg_red;         $stdout.isatty ? "\e[41m#{self}\e[0m" : self end
  def bg_green;       $stdout.isatty ? "\e[42m#{self}\e[0m" : self end
  def bg_brown;       $stdout.isatty ? "\e[43m#{self}\e[0m" : self end
  def bg_blue;        $stdout.isatty ? "\e[44m#{self}\e[0m" : self end
  def bg_magenta;     $stdout.isatty ? "\e[45m#{self}\e[0m" : self end
  def bg_cyan;        $stdout.isatty ? "\e[46m#{self}\e[0m" : self end
  def bg_gray;        $stdout.isatty ? "\e[47m#{self}\e[0m" : self end
  def bold;           $stdout.isatty ? "\e[1m#{self}\e[22m" : self end
  def italic;         $stdout.isatty ? "\e[3m#{self}\e[23m" : self end
  def underline;      $stdout.isatty ? "\e[4m#{self}\e[24m" : self end
  def blink;          $stdout.isatty ? "\e[5m#{self}\e[25m" : self end
  def reverse_color;  $stdout.isatty ? "\e[7m#{self}\e[27m" : self end
end
