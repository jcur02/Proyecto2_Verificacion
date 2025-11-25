`include "uvm_macros.svh"
import uvm_pkg::*;

class trans_monitor extends uvm_monitor;
  `uvm_component_utils(trans_monitor)

  localparam int PCK_SZ = 40;

    // constructor
  function new(string name = "trans_monitor", uvm_component parent = null);
    super.new(name, parent);
    cg = new();
  endfunction

  uvm_analysis_port#(trans_item) ap;
  virtual mesh_gnrt_if vif;

  bit seen[16];
  time last_recv_time[16];
  integer csv_fd;
  // Variables para cobertura
  int cov_src_terminal;
  int cov_receptor;
  int cov_row, cov_col;
  bit cov_mode;
  int unsigned cov_delay;

  // --------- Cobertura funcional --------------
  covergroup cg;
    // terminal fuente y destino
    cp_src : coverpoint cov_src_terminal {
      bins all_terms[] = {[0:15]};
    }
    cp_dst : coverpoint cov_receptor {
      bins all_terms[] = {[0:15]};
    }

    // fila y columna de destino
    cp_row : coverpoint cov_row {
      bins rows[] = {[0:5]};
    }

    cp_col : coverpoint cov_col {
      bins cols[] = {[0:5]};
    }

    // modo de operación
    cp_mode : coverpoint cov_mode {
      bins modo0 = {0};
      bins modo1 = {1};
    }

    // retardo 
    cp_delay : coverpoint cov_delay {
      bins corto  = {[0:10]};
      bins medio  = {[11:50]};
      bins largo  = {[51:$]};
    }

    // crosses
    cr_dst_row_col : cross cp_dst, cp_row, cp_col;
    cr_src_dst     : cross cp_src, cp_dst;
  endgroup : cg

    // build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual mesh_gnrt_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Could not get vif")
    ap = new("mon_analysis_port", this);

    foreach (seen[i]) seen[i] = 1'b0;
    
    // Abrir CSV y escribir encabezado
    csv_fd = $fopen("reporte_paquetes.csv", "w");
    if (csv_fd == 0)
      `uvm_fatal("MON", "No se pudo abrir reporte_paquetes.csv")

    // Encabezado
      $fwrite(csv_fd, "t_envio,terminal_src,terminal_dst,row_dst,col_dst,t_recibo,retardo,delta_t,bw_bits_per_cycle\n");
  endfunction

    // run phase
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    sample_port("MON");
  endtask

    // task para el monitoreo
  virtual task sample_port(string tag="");
    int i;
    int  row, col, src_terminal;
    time t_recv, t_send, delay;
    time delta_t, bw_bits;
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

          // ---- Recuperar info de envío para este destino ----
          row    = item.target_row_out;
          col    = item.target_column_out;
          t_recv = $time;

          if (trans_item::send_t_send[row][col].size() > 0) begin
            t_send       = trans_item::send_t_send[row][col].pop_front();
            src_terminal = trans_item::send_src[row][col].pop_front();
            delay        = t_recv - t_send;
          end
          else begin
            t_send       = 0;
            src_terminal = -1;
            delay        = 0;
          end

          // ---- Calcular delta_t y ancho de banda ----
          if (last_recv_time[item.receptor] == 0) begin
            delta_t = 0;
            bw_bits = 0;
          end
          else begin
            delta_t = t_recv - last_recv_time[item.receptor];
            if (delta_t == 0)
              bw_bits = 0;
            else
              bw_bits = PCK_SZ / delta_t; // 40 bits / ciclos 
          end
          last_recv_time[item.receptor] = t_recv;

          // ---- Escribir al CSV ----
          // t_envio,terminal_src,terminal_dst,row_dst,col_dst,t_recibo,retardo,delta_t,bw_bits_per_cycle
          $fwrite(csv_fd, "%0t,%0d,%0d,%0d,%0d,%0t,%0t,%0t,%0t\n",
                  t_send, src_terminal, item.receptor,
                  row, col, t_recv, delay, delta_t, bw_bits);
		      // ---- Cobertura: cargar variables y samplear ----
          cov_src_terminal = src_terminal;
          cov_receptor     = item.receptor;
          cov_row          = row;
          cov_col          = col;
          cov_mode         = item.mode;
          cov_delay        = delay;   

          cg.sample();
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

  virtual function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    if (csv_fd)
      $fclose(csv_fd);
  endfunction
endclass