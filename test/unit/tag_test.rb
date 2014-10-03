require_relative 'test_helper'
require 'set'

class TagTest < ActiveSupport::TestCase
  fixtures :pages
  def setup
    @obj = Page.first
    @obj.tag_list = "robot, flower, watermelon"
    @obj.save!
  end

  def test_to_s
    assert_equal Set.new(['robot','flower','watermelon']), Set.new(Page.first.tag_list)
  end

end
