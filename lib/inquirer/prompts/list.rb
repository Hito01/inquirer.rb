require 'term/ansicolor'

# Base rendering for simple lists
module ListRendererBase
  def render heading = nil, list = [], footer = nil
    # render the heading
    ( heading.nil? ? "" : self::Heading % heading ) +
    # render the list
    list.map do |li|
      li["selected"] ? selected(li["value"]) : unselected(li["value"])
    end.join("") +
    # render the footer
    ( footer.nil? ? "" : self::Footer % footer )
  end

  private

  def selected x
    self::Selector + " " + self::SelectedItem % x
  end

  def unselected x
    "  " + self::Item % x
  end
end

# Simple formatting for list rendering
module ListRendererSimple
  include ListRendererBase
  include Term::ANSIColor
  extend self
  Heading = "%s:\n"
  Footer = "%s\n"
  Item = "%s\n"
  SelectedItem = cyan("%s") + "\n"
  Selector = cyan ">"
end

# Default formatting for list rendering
module ListRenderer
  include ListRendererSimple
  extend self
  Selector = cyan "‣"
end

class List
  def initialize question = nil, elements = [], renderer = ListRenderer
    @elements = elements
    @question = question
    @pos = 0
    @prompt = ""
    @renderer = renderer
  end

  def update_prompt
    # transform the list into
    # {"value"=>..., "selected"=> true|false}
    e = @elements.
      # attach the array position
      map.with_index(0).
      map do |c,pos|
        { "value"=>c, "selected" => pos == @pos }
      end
    # call the renderer
    @prompt = @renderer.render(@question, e)
  end

  def run
    IOHelper.render( update_prompt )

    IOHelper.read_key_while do |key|
      @pos = (@pos - 1) % @elements.length if key == "up"
      @pos = (@pos + 1) % @elements.length if key == "down"
      IOHelper.clear
      IOHelper.render( update_prompt )
      # we are done if the user hits return
      key != "return"
    end
    # clear the final prompt and the line
    IOHelper.clear
    # return the index of the selected item
    @pos
  end

  def self.ask *args
    l = List.new *args
    l.run
  end

end