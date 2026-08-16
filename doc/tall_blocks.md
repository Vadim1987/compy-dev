Buffer visibility check is what effectively triggers non-saving

and visibility check happens inside view/editor/bufferView.lua ... comes from 
content:get_block_app_pos(sel) 
    but where the selection comes from? from buffer:get_selection()
      its also a primitive type, most likely *int*?
      its just a number of the block
vs 
content:get_range() --> just returns Range, a primitive utils type, which is a wrapped attribute.
    now I wonder what changes it?

  -- hint: we also have content:get_content_range



range is a primitive utils tyep

where content is VisibleStructuredContent



==========================

  if: selection not visible BUT visible partially
  if: chunks > 1
    memoize current selection
    memoize which chunk is bigger than range size -2  BAD CHUNK NUMBER
    buffer model : replace_content(sel. new chunks) #### it does rechunking
    if bad chunk number:
      move to prev_sel + bad_chunk_number -> load
    else: 
      move to prev_sel + #chunks



==========================

✦ The search confirms input_max is used in several key places, most notably:                                                                                                                                  
   * src/main.lua: Sets a default value of 14.                                                                                                                                                                
   * src/model/input/userInputModel.lua: The input model uses it.                                                                                                                                             
   * src/view/input/userInputView.lua: The input view uses it to calculate its height.                                                                                                                        
                                                                                                                                                                                                              
  This confirms that 14 is the maximum number of lines for the user input area. It's a view constraint, not a validation constraint. This is a crucial distinction. It means the system doesn't "refuse to    
  save" because the block is too tall; rather, the input box itself is of a fixed height.                                                                                                                     
                                                                                                                                                                                                              
  Now, let's connect this to the "weird formatting" and the user's request.                                                                                                                                   
                                                                                                                                                                                                              
  When you edit a block (the "yellow block"), its content is loaded into this 14-line input area. If the block is already taller than 14 lines, it still gets loaded, but you can only see 14 lines at a      
  time. When you press Enter to save, the _handle_submit function is called:                                                                                                                                  
                                                                                                                                                                                                              
   1. It takes all the text from the input area.                                                                                                                                                              
   2. It sends it to the pretty-printer (buf.printer, which is pprint).                                                                                                                                       
   3. The pretty-printer (ast_to_src.lua) reformats the entire block according to its rules, likely causing the "weird indents" you saw as it tries to fit the code aesthetically. It doesn't know or care    
      about the 14-line limit of the view.                                                                                                                                                                    
   4. The entire reformatted block is then saved back, replacing the original.                                                                                                                                
                                                                                                                                                                                                              
  Revisiting the User's Goal with This New Understanding:                                                                                                                                                     
                                                                                                                                                                                                              
  The user wants to edit a tall function (e.g., 20 lines) and split it.                                                                                                                                       
                                                                                                                                                                                                              
   * Current problem: If they delete the bottom part of the function in the input view and press Enter, the pretty-printer gets the incomplete function text, which is a syntax error. The save fails, or the 
     pretty-printer might mangle it. They can't just "save the top part."                                                                                                                                     
                                                                                                                                                                                                              
   * Desired behavior: They want the editor to be smart enough to recognize this situation. If the user edits a 20-line function down to a valid, complete 10-line function in the input box, the system      
     should:                                                                                                                                                                                                  
       1. Recognize that the newly edited code is a valid, complete block on its own.                                                                                                                         
       2. Save this new, shorter block.                                                                                                                                                                       
       3. Leave the remaining part of the original block (the lines that were "scrolled off" the bottom of the input view) in the editor to be dealt with next. This is the "split" operation.                
                                                                                                                                                                                                              
  This aligns perfectly with the code change I implemented. My solution detects when the input text can be chunked into a valid first part and a remainder. It commits the valid part and keeps the remainder 
  in the input for the next action. The fact that the trigger is a line-limit overflow (causing the user to not see all the code) vs. a character-width overflow doesn't change the required logic. The       
  solution should work as intended for this use case.   
