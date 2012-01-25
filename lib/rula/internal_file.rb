module Rula
  #
  # InternalFile performs oprations on selected file and coordinates between buffers and files
  # This is entry point from the interface
  #
  class InternalFile
    @@BLOCK_SIZE = 1024*8
    @@BUFFERS = 5

    CONST = {
      :forward => 1,
      :backward => 2,
      :skip => 3
    }.freeze

    attr_reader :filename, :file_lines, :file_size

    def initialize(filename)
      @filename = filename
      @file_size = File.size?(@filename)
      @file_lines = 0
      @active_buffer = 0
      @buffers = Array.new(@@BUFFERS) {|x| InternalFileBuffer.new(x)}
      @file_eof = false
      self
    end

    #
    # Called when selected file is first opened to fill in buffers with adjusted block positions. Adjusted position
    # is to remove lines that were read in half. Adjustment is done towards previos new line.
    #
    def count_lines()
      start_time = Time.now
      @file_lines = 0      
      last_block_position = 0
      prev_block_position = -1
      Rula.log(Logger::DEBUG,"Reading file #{@filename} lines count",self)
      file_handle = File.open(@filename,'rb')
      while data = file_handle.read(@@BLOCK_SIZE)
        original_size = data.length
        last_occurence = data.rindex(Rula.options[:line_separator])
        difference_in_size = original_size - last_occurence

        if data.length==1 then
          break
        end

        if !last_occurence.nil? then
          data = data[0..last_occurence]
          file_handle.pos -= difference_in_size
        end
        @file_lines += data.scan(/([^|#{Rula.options[:line_separator]}].*)#{Rula.options[:line_separator]}/).length
        
        (0...@@BUFFERS).each {|i| 
          @buffers[i].add_hash(last_block_position, prev_block_position, file_handle.pos, @file_lines)
        }
        prev_block_position = last_block_position                        
        last_block_position = file_handle.pos
      end
      Rula.log(Logger::DEBUG,"Counted #{@file_lines} lines for file #{@filename}",self)
    ensure
      Rula.log(Logger::DEBUG,"Counting lines ran #{(Time.now - start_time) * 1000} ms",self)
      file_handle.close()
      load_buffer_data(0)
    end

    #
    # This is used to get all available buffers
    #
    def get_buffers()
      Rula.log(Logger::DEBUG,"Getting buffers",self)
      @buffers
    end
    
    def get_buffer(buffer=0)
      Rula.log(Logger::DEBUG,"Getting buffer #{buffer}",self)
      @buffers[buffer] unless !buffer.between?(0,@@BUFFERS)
    end

    #
    # Get currently used buffer
    #
    def get_active_buffer()
      Rula.log(Logger::DEBUG,"Get active buffer: #{@active_buffer}",self)
      @buffers[@active_buffer]
    end

    #
    # Change currently used buffer
    #
    def set_active_buffer(buffer=0)      
      @active_buffer = buffer unless !buffer.between?(0,@@BUFFERS)
      @file_eof = false
      Rula.log(Logger::DEBUG,"Set active buffer to #{@active_buffer}",self)
    end

    def get_buffer_data(action,start_line,count)      
      Rula.log(Logger::DEBUG,"Getting buffer data for lines #{start_line} and count #{count}",self)
            
      temp_buffer = []
      used_keys = []       
   
      key = @buffers[@active_buffer].get_buffer_key(start_line)
      Rula.log(Logger::DEBUG,"Found key #{key} for line #{start_line}",self) if !key.nil?
      
      if key.nil? then    
        Rula.log(Logger::DEBUG,"Key not found",self)
        return [-1,"Not found or EOF"]
      else        
        while key do
          used_keys.push(key)       
          has_data = @buffers[@active_buffer].get_hash(key)[Rula::CONST[:buffer_has_data]]              
          Rula.log(Logger::DEBUG,"Does key #{key||'nil'} have data? (#{has_data})",self)
          load_buffer_data(key) if !has_data                      
              
          if action==InternalFile::CONST[:backward] then
            temp_buffer = @buffers[@active_buffer].get_hash(key)[Rula::CONST[:buffer]] + temp_buffer
          else
            temp_buffer = temp_buffer + @buffers[@active_buffer].get_hash(key)[Rula::CONST[:buffer]]
          end                         
          Rula.log(Logger::DEBUG,"Total number of lines is #{temp_buffer.length}",self)
           
          if has_enough_data(action,temp_buffer,start_line,count) or (@file_eof and action!=InternalFile::CONST[:backward])  then
            @buffers[@active_buffer].clean_buffers_other_than(used_keys)
            return temp_buffer
          else
            key = @buffers[@active_buffer].get_next_buffer(key) if action==InternalFile::CONST[:forward] or action==InternalFile::CONST[:skip]
            key = @buffers[@active_buffer].get_prev_buffer(key) if action==InternalFile::CONST[:backward]   
            Rula.log(Logger::DEBUG,"Obtained buffer is #{key||'nil'}",self)           
          end
          Rula.log(Logger::DEBUG,"File EOF reached",self) if @file_eof                   
        end             
        return temp_buffer          
      end           
    end
    
    
    #
    # Used to search data. Search data can be set to buffers > 0. Buffer 0 is used for the whole file only.
    # Parameters: 
    #   search - this is regex for the search
    # Return:
    #   nil 
    #
    def search_data(search)           
      key = 0
      found = 0    
      @buffers[@active_buffer].last_displayed_line = 0
      @buffers[@active_buffer].clean_buffers_other_than([]) #clean all buffers
      @buffers[@active_buffer].add_previous_search(@buffers[@active_buffer-1].regex_array)       
      while data = read_file(key) do      
        break if data.length==1   
        set_data = @buffers[@active_buffer].loaded_data_size < @@BLOCK_SIZE*2     
        found += @buffers[@active_buffer].set_buffer_data(key,data,search,set_data)[1]          
        key = @buffers[@active_buffer].get_next_buffer(key)
        break if key.nil?  
      end
      Rula.log(Logger::INFO,"Found #{found} items",self) 
      @file_eof = false
    end

    private

    def has_enough_data(action,temp_buffer,start_line,count)
      Rula.log(Logger::DEBUG,"Checking if buffer has enough data",self)    
      
      return false if temp_buffer.empty? 
            
      start_line = temp_buffer[0][0] if start_line==0   
      Rula.log(Logger::DEBUG,"Start line is #{start_line}",self)     
      line_index = temp_buffer.index{|x| x[0].to_i>=start_line} 
      Rula.log(Logger::DEBUG,"Index is #{line_index||'nil'}",self)
      
      # TODO if line index is nil then search next line, if there are no lines, then say that there is not enough data
      
      if action==InternalFile::CONST[:forward] or action==InternalFile::CONST[:skip] then                        
        if line_index.nil? or temp_buffer.length()-line_index<count then
          Rula.log(Logger::DEBUG,"Buffer does not have enough data",self)
          return false
        else
          Rula.log(Logger::DEBUG,"Buffer has enough data",self)
          return true
        end
      else       
        if line_index.nil? or line_index<count.abs() then
          Rula.log(Logger::DEBUG,"Buffer does not have enough data",self)
          return false
        else
          Rula.log(Logger::DEBUG,"Buffer has enough data",self)
          return true
        end        
      end
    end
    
    #
    # Call to set buffer data and read file in block
    # Parameters:
    #   key - this is key to has in the buffer and also block start position
    # Return:
    #   nil
    #
    def load_buffer_data(key)
        @buffers[@active_buffer].set_buffer_data(key,read_file(key))
    end

    #
    # Perform block read of the file
    #
    def read_file(block=0)
      Rula.log(Logger::DEBUG,"Reading file #{filename} block #{block}",self)
      return nil if(block >= @file_size)
      return nil if(block < 0)
      file_handle = File.open(@filename,'rb')
      file_handle.pos = block
      @previous_block_read = file_handle.pos
      data = file_handle.read(@@BLOCK_SIZE)
      @last_block_read = file_handle.pos
      Rula.log(Logger::DEBUG,"Read #{data.length} bytes",self)
      @file_eof = file_handle.eof
      return data
    ensure      
      file_handle.close() unless file_handle.nil?
    end
  end
end