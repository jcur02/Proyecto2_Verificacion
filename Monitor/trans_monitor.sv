`include "uvm_macros.svh"
import uvm_pkg::*;

class trans_monitor extends uvm_monitor;
  `uvm_component_utils(trans_monitor)

  localparam int PCK_SZ = 40;

    // constructor
  function new(string name = "trans_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  uvm_analysis_port#(trans_item) ap;
  virtual mesh_gnrt_if vif;

  bit seen[16];

    // build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual mesh_gnrt_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Could not get vif")
    ap = new("mon_analysis_port", this);

    foreach (seen[i]) seen[i] = 1'b0;
  endfunction

    // run phase
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    sample_port("MON");
  endtask

    // task para el monitoreo
  virtual task sample_port(string tag="");
    int i;
    forever begin
      @(posedge vif.clk);
      // revisar cada device
      for (i = 0; i < 16; i++) begin
        // revisar si hay dato y no ha sido contado antes
        if (vif.pndng[i] && !seen[i]) begin
          trans_item item = new;

          item.packet   = vif.data_out[i];
          // indicar receptor
          item.receptor = i;

            // extraer campos del paquete
          { item.next_jump,
            item.target_row_out,
            item.target_column_out,
            item.mode,
            item.payload } = vif.data_out[i];

            // enviar item al scoreboard
          ap.write(item);
          `uvm_info("MON", $sformatf("T=%0t [Monitor] %s over, item:", 
                                     $time, tag), UVM_LOW)
          item.print();

          vif.pop[i] <= 1'b1;
          seen[i]    = 1'b1;   // marcamos que ya lo contamos
        end
        // limpiar pop si pndng es 0
        else if (!vif.pndng[i]) begin
          vif.pop[i] <= 1'b0;
          seen[i]    = 1'b0;
        end
      end
    end
  endtask
endclass