`include "uvm_macros.svh"
import uvm_pkg::*;

// Secuencia que genera 5 transacciones por cada terminal de origen (0-15)
// con el mismo destino (0,1) y gap 0
class all_src_same_dst_seq extends uvm_sequence #(trans_item);
  `uvm_object_utils(all_src_same_dst_seq)

  function new(string name = "all_src_same_dst_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    for (int s = 0; s < 16; s++) begin
      for (int k = 0; k < 5; k++) begin
        trans_item it = trans_item::type_id::create($sformatf("it_%0d_%0d", s, k));
        start_item(it);
        assert(it.randomize() with {
          sender           == s;
          target_row_out    == 0;
          target_column_out == 1;
          send_gap          == 0;
        });
        `uvm_info("SEQ", $sformatf("Generate item from terminal %0d with gap of %0d", s, it.send_gap), UVM_LOW)
        finish_item(it);
      end
    end
  endtask
endclass