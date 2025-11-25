interface mesh_gnrt_if(input bit clk);
  logic reset;
  logic pndng[16];
  logic [39:0] data_out[16];
  logic popin[16];
  logic pop[16];
  logic [39:0] data_out_i_in[16];
  logic pndng_i_in[16];

  // =================================================
  // Aserciones
  // =================================================
  genvar gi;
  generate
    for (gi = 0; gi < 16; gi++) begin : ASSERTS

      // 1) No sacar pop si no hay pendiente
      property pop_only_if_pndng;
        @(posedge clk) disable iff (reset)
          pop[gi] |-> (pndng[gi] or $past(pndng[gi]));
      endproperty
      assert_pop_only_if_pndng: assert property (pop_only_if_pndng)
        else $error("POP sin PNDNG en terminal %0d", gi);

      // 2) Si hay pndng, eventualmente debe haber pop
      property pndng_eventually_pop;
        @(posedge clk) disable iff (reset)
        $rose(pndng[gi]) |-> ##[1:100] pop[gi];
      endproperty
      assert_pndng_eventually_pop: assert property (pndng_eventually_pop)
        else $error("PNDNG en %0d no atendido en 20 ciclos", gi);

      // 3) pndng_i_in debe generar popin pronto
      property in_pndng_eventually_popin;
        @(posedge clk) disable iff (reset)
        $rose(pndng_i_in[gi]) |-> ##[1:100] popin[gi];
      endproperty
      assert_in_pndng_eventually_popin: assert property (in_pndng_eventually_popin)
        else $error("PNDNG_I_IN en %0d no genera POPIN en 20 ciclos", gi);

    end
  endgenerate
endinterface