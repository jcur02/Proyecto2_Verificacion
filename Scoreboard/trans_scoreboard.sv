`include "uvm_macros.svh"
import uvm_pkg::*;

class trans_scoreboard extends uvm_component;
  `uvm_component_utils(trans_scoreboard)

    // constructor
  function new(string name = "trans_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  uvm_analysis_imp#(trans_item, trans_scoreboard) mon_imp;

    //  build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_imp = new("m_analysis_imp", this);
  endfunction

  // funcion para validar la transaccion recibida
  virtual function void write(trans_item t);
    if (t.receptor == 0) begin
      if (t.target_row_out != 0 | t.target_column_out != 1)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
    end
    else if (t.receptor == 1) begin
      if (t.target_row_out != 0 | t.target_column_out != 2)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 2) begin
      if (t.target_row_out != 0 | t.target_column_out != 3)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 3) begin
      if (t.target_row_out != 0 | t.target_column_out != 4)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 4) begin
      if (t.target_row_out != 1 | t.target_column_out != 0)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 5) begin
      if (t.target_row_out != 2 | t.target_column_out != 0)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 6) begin
      if (t.target_row_out != 3 | t.target_column_out != 0)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 7) begin
      if (t.target_row_out != 4 | t.target_column_out != 0)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 8) begin
      if (t.target_row_out != 5 | t.target_column_out != 1)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 9) begin
      if (t.target_row_out != 5 | t.target_column_out != 2)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 10) begin
      if (t.target_row_out != 5 | t.target_column_out != 3)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 11) begin
      if (t.target_row_out != 5 | t.target_column_out != 4)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 12) begin
      if (t.target_row_out != 1 | t.target_column_out != 5)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 13) begin
      if (t.target_row_out != 2 | t.target_column_out != 5)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 14) begin
      if (t.target_row_out != 3 | t.target_column_out != 5)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 15) begin
      if (t.target_row_out != 4 | t.target_column_out != 5)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
        
  endfunction 
endclass