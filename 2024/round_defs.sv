`ifndef ROUND_MODE_DEF
`define ROUND_MODE_DEF

typedef enum logic [2:0] {
  IEEE_NEAR   = 3'b000,
  IEEE_ZERO   = 3'b001,
  IEEE_PINF   = 3'b010,
  IEEE_NINF   = 3'b011,
  NEAR_UP     = 3'b100,
  AWAY_ZERO   = 3'b101
} round_mode_t;

`endif
