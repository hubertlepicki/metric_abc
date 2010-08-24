require 'ripper'
require 'pp' if ENV["DEBUG"]

class MetricABC
  attr_accessor :ast, :complexity

  def initialize(file_name)
    File.open(file_name, "r") do |f|
      @ast = Ripper::SexpBuilder.new(f.read).parse
    end  
    return if @ast.empty?
    @complexity = {}
    @nesting = []
    process_ast(@ast)
    pp @ast if ENV["DEBUG"]
  end 

  def process_ast(node)
    backup_nesting = @nesting.clone
     
    if node[0] == :def
      @nesting << node[1][1]
      @complexity[@nesting.join("#")] = calculate_abc(node)
    elsif node[0] == :class || node[0] == :module
      @nesting << node[1][1][1]
    end  

    node[1..-1].each { |n| process_ast(n) if n } if node.is_a? Array
    @nesting = backup_nesting
  end

  def calculate_abc(method_node)
    a = calculate_assignments(method_node)
    b = calculate_branches(method_node)
    c = calculate_conditions(method_node)
    Math.sqrt(a**2 + b**2 + c**2).round
  end

  def calculate_assignments(node)
    node.flatten.select{|n| [:assign, :opassign].include?(n)}.size.to_f
  end

  def calculate_branches(node)
    node.flatten.select{|n| [:call, :fcall, :brace_block, :do_block].include?(n)}.size.to_f + 1.0
  end

  def calculate_conditions(node, sum=0)
    node.flatten.select{|n| [:==, :===, :"<>", :"<=", :">=", :"=~", :>, :<, :else, :"<=>"].include?(n)}.size.to_f 
  end
end
