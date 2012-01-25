module Rula
  #
  # Internal buffer for storing temp data
  #
  class InternalFileBuffer
    attr_accessor :last_displayed_line
    attr_reader :id, :buffer_hash, :loaded_data_size, :regex_array
    def initialize(id=0)
      @id = id #id of internal buffer
      @regex_array = [Regexp.new('([^|'+Rula.options[:line_separator]+'].*)'+Rula.options[:line_separator])] 
      @buffer_hash = {
        0=>[0,0,0,[],false]
      } # hash_id=>prev_hash, next_hash, end_line, buffer[line,data], has_data 
      @last_displayed_line = 0 #this is used to display last line in interface and is used to determine if we need to load next/previous buffer
      @loaded_data_size = 0
      Rula.log(Logger::DEBUG,"Initializing internal buffer id #{@id}",self)
    end

    #
    # This is used to initialize hash and create placeholders with start/stop positions of the block
    # 
    def add_hash(hash_id=0, prev_hash_id=0, next_hash_id=0, lines=0) 
      @buffer_hash[hash_id] = [prev_hash_id,next_hash_id,lines,[],false]
    end
    
    def add_previous_search(previous_search)
      @regex_array = []
      @regex_array += previous_search
    end

    def set_buffer_data(hash_id,data,search_regex_string=nil,set_data=true)
      Rula.log(Logger::DEBUG,"Setting buffer data to hash id #{hash_id}",self)
      
      # every buffer has 1 extra search 
      # this is used when assisgning new buffer so we can copy previousely searched regex
      if @regex_array[@id].nil? and !search_regex_string.nil? and @id>0 then
        @regex_array.push(Regexp.new(search_regex_string))
      end
       
      regex_found = 0
      
      if hash_id == @buffer_hash[hash_id][Rula::CONST[:prev_hash_id]] or @buffer_hash[hash_id][Rula::CONST[:prev_hash_id]]==-1then
        line_number = 0
      else
        line_number = @buffer_hash[@buffer_hash[hash_id][Rula::CONST[:prev_hash_id]]][Rula::CONST[:last_line]]
      end

      @buffer_hash[hash_id][Rula::CONST[:buffer]] = [] if set_data

      data.scan(@regex_array[0]) {|line|        
        line_number+=1        
        if @regex_array.length>1 then  
          found = false
          (1..@regex_array.length-1).each { |i|            
            found = line[0] =~ @regex_array[i]
            break if !found                         
          }                  
          if found then
            regex_found += 1       
            @buffer_hash[hash_id][Rula::CONST[:buffer]].push([line_number,line]) if set_data
          end
        else
          @buffer_hash[hash_id][Rula::CONST[:buffer]].push([line_number,line]) if set_data
        end        
      }
      
      @buffer_hash[hash_id][Rula::CONST[:last_line]] = line_number if set_data
      @buffer_hash[hash_id][Rula::CONST[:buffer_has_data]] = true unless @buffer_hash[hash_id][Rula::CONST[:buffer]].empty? and !set_data 

      Rula.log(Logger::DEBUG,"Found #{regex_found} items hash id #{hash_id}",self)              
      
      @loaded_data_size += calculate_size(@buffer_hash[hash_id][Rula::CONST[:buffer]]) if set_data
      
      return [0,regex_found]
    end

    def clear_buffer_data(key)
      @buffer_hash[key][Rula::CONST[:buffer]]=[]
      @buffer_hash[key][Rula::CONST[:buffer_has_data]] = false
    end
    
    def get_hash(key)
      return @buffer_hash[key]
    end
    
    def get_next_buffer(key)
      Rula.log(Logger::DEBUG,"Getting next buffer",self)
      @buffer_hash[key][Rula::CONST[:next_hash_id]] if @buffer_hash[@buffer_hash[key][Rula::CONST[:next_hash_id]]]
    end
    
    def get_prev_buffer(key)
      Rula.log(Logger::DEBUG,"Getting prev buffer",self)
      @buffer_hash[key][Rula::CONST[:prev_hash_id]] if @buffer_hash[@buffer_hash[key][Rula::CONST[:prev_hash_id]]]
    end

    #
    # use line to find which key has it
    #
    def get_buffer_key(start_line=0)
      @buffer_hash.each { |key, value|
        if start_line<=value[Rula::CONST[:last_line]] then
          return key
        end
      }
      return nil
    end

    #
    # Cleaning buffer is needed to remove extra data that is currently not beeing viewed.
    #
    def clean_buffers_other_than(used_keys)
      @buffer_hash.each { |key, value|
        if !used_keys.index(key) then
          if value[Rula::CONST[:buffer_has_data]] then
            Rula.log(Logger::DEBUG,"Cleaning buffer #{key}",self)
            @loaded_data_size -= calculate_size(value[Rula::CONST[:buffer]])
            value[Rula::CONST[:buffer]]=[]
            value[Rula::CONST[:buffer_has_data]]=false
          end
        end
      }
      @loaded_data_size = @loaded_data_size < 0 ? 0: @loaded_data_size
    end
    
    private
    
    def calculate_size(buffer)
      size = 0
      buffer.each { |x|
        size += x[0].size+ x[1].to_s.bytesize
      }
      return size
    end
  end
end