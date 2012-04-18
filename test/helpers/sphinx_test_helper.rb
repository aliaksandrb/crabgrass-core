module SphinxTestHelper
  def print_sphinx_hints
    @@sphinx_hints_printed ||= false
    unless @@sphinx_hints_printed
    # cg:update_page_terms
      puts "\nTo make thinking_sphinx tests not skip, try the following steps:
  rake db:test:prepare                     # should not be necessary
  rake RAILS_ENV=test db:fixtures:load     # frankly, I am not sure if this is still necessary
  rake RAILS_ENV=test ts:index ts:start    # necessary! needed to build the sphinx index and start searchd.
See also doc/SPHINX"
      @@sphinx_hints_printed = true
    end

  end

  def sphinx_working?(test_name="")
    if !ThinkingSphinx.sphinx_running?
      putc 'S'
      print_sphinx_hints
      false
    else
      true
    end
  end
end
