class Pgq<%= name_c %> < Pgq::Consumer

  # to insert event: Pgq<%= name_c %>.my_event(1, 2, 3)
  
  # async execute
  def my_event(a, b, c)
    logger.info "async call my_event with #{[a, b, c].inspect}"
  end
  
end
