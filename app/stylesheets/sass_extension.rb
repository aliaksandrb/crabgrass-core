# define here new extensions you want available in sass 
# stylesheets.

module Sass::Script::Functions
  # takes a border string, like '1px solid green'
  # and returns 1px
  def border_size(string)
    Sass::Script::Number.new( string.to_s.split(' ').first.to_i, ['px'])
  end

  def border_color(string)
    assert_type string, :String
    Sass::Script::String.new(string.to_s.split(' ').last)
  end

  # allows special width unit 'g', for gutter.
  # 1g = the width of the susy gutter.
  def resolve_width(string, context_columns = false)
    if string.to_s.gsub('"','').match(/([0-9\.]+)g$/) # ends with 'g'?
      # gutter() is defined in susy plugin in sass_extensions.rb
      gutter(context_columns).times(Sass::Script::Number.new($1.to_f))
    else
      string
    end
  end

end


