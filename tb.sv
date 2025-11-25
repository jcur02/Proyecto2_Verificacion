`include "uvm_macros.svh"
import uvm_pkg::*;

module tb;
  reg clk;
  
  always #10 clk =~ clk;
  mesh_gnrt_if 	_if (clk);
  mesh_gnrtr u0 ( 	.clk(clk),
             .pndng(_if.pndng),
             .data_out(_if.data_out),
             .popin (_if.popin),
             .pop(_if.pop),
             .data_out_i_in(_if.data_out_i_in),
             .pndng_i_in(_if.pndng_i_in),
             .reset(_if.reset));
  trans_test t0;
  
  initial begin
    clk <= 0;
    uvm_config_db#(virtual mesh_gnrt_if)::set(null, "uvm_test_top", "vif", _if);
    run_test("trans_test");
    //run_test("trans_test_reset_mid_traffic");
  end
  
  initial begin
    $dumpvars;
    $dumpfile ("dump.vcd");
  end
endmodule