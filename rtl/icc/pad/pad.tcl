# ===   create corner / power / ground    ================================================
# corner
create_cell {corner_tl corner_tr corner_bl corner_br} CORNER
# power / ground : io
create_cell {io_vss_t  io_vss_b                     } IOVDD
create_cell {io_vdd_l  io_vdd_r                     } IOVSS
# power / ground : core 
create_cell {vdd_t     vdd_b     vdd_l     vdd_r    } VDD
create_cell {vss_t     vss_b     vss_l     vss_r    } VSS


# ===   set position   ==================================================================

# side:
#            2 
#         1     3
#            4

# ---    corner   -------------------------------------------------------------
# tl tr
# bl br
set_pad_physical_constraints -pad_name { corner_tl        }   -side 1
set_pad_physical_constraints -pad_name { corner_tr        }   -side 2
set_pad_physical_constraints -pad_name { corner_br        }   -side 3
set_pad_physical_constraints -pad_name { corner_bl        }   -side 4


# ---    io   -----------------------------------------------------------------

#    1 2 3
#    ------------------------------------------------------------------------------------->
#    ^              dat_i[0-10] / vdd_t / vss_t / io_vss_t / dat_i[11-21]                 ^
#    |  val_i                                                                dat_i[22-31] |
#    |  cfg_h[0-8]                                                           io_vdd_r     |
#    |  io_vdd_l                                                             vdd_r        |
#    |  vdd_l                                                                vss_r        |
#    |  vss_l                                                                done         |
#    |  cfg_w[0-8]                                                           val_o        |
#    |  start                                                                dat_o[0-9]   |
#    |  rst                                                                  io_vdd_r     |
#  3 |  clk                                                                               | 3
#  2 |                                                                                    | 2
#  1 |               dat_o[31-21] / vdd_b / vss_b / io_vss_b / dat_o[20-10]               | 1
#    ------------------------------------------------------------------------------------->
#    1 2 3

# correct pad direction
#        N:0
# W:90          E:270
#        S:180 
# set_pad_physical_constraints -pad_name I1025    -lib_cell_orientation {E E E E}
# set_pad_physical_constraints -pad_name B12I1025 -lib_cell_orientation {E E E E}

# 1: left
set_pad_physical_constraints -pad_name { I1025_clk        }   -side 1 -order 1
set_pad_physical_constraints -pad_name { I1025_rstn       }   -side 1 -order 2
set_pad_physical_constraints -pad_name { I1025_start_i    }   -side 1 -order 3

set_pad_physical_constraints -pad_name { I1025_cfg_h_i_0  }   -side 1 -order 4
set_pad_physical_constraints -pad_name { I1025_cfg_h_i_1  }   -side 1 -order 5
set_pad_physical_constraints -pad_name { I1025_cfg_h_i_2  }   -side 1 -order 6
set_pad_physical_constraints -pad_name { I1025_cfg_h_i_3  }   -side 1 -order 7
set_pad_physical_constraints -pad_name { I1025_cfg_h_i_4  }   -side 1 -order 8
set_pad_physical_constraints -pad_name { I1025_cfg_h_i_5  }   -side 1 -order 9
set_pad_physical_constraints -pad_name { I1025_cfg_h_i_6  }   -side 1 -order 10
set_pad_physical_constraints -pad_name { I1025_cfg_h_i_7  }   -side 1 -order 11
set_pad_physical_constraints -pad_name { I1025_cfg_h_i_8  }   -side 1 -order 12


set_pad_physical_constraints -pad_name { vss_l            }   -side 1 -order 13
set_pad_physical_constraints -pad_name { vdd_l            }   -side 1 -order 14
set_pad_physical_constraints -pad_name { io_vdd_l         }   -side 1 -order 15

set_pad_physical_constraints -pad_name { I1025_cfg_w_i_0  }   -side 1 -order 16
set_pad_physical_constraints -pad_name { I1025_cfg_w_i_1  }   -side 1 -order 17
set_pad_physical_constraints -pad_name { I1025_cfg_w_i_2  }   -side 1 -order 18
set_pad_physical_constraints -pad_name { I1025_cfg_w_i_3  }   -side 1 -order 19
set_pad_physical_constraints -pad_name { I1025_cfg_w_i_4  }   -side 1 -order 20
set_pad_physical_constraints -pad_name { I1025_cfg_w_i_5  }   -side 1 -order 21
set_pad_physical_constraints -pad_name { I1025_cfg_w_i_6  }   -side 1 -order 22
set_pad_physical_constraints -pad_name { I1025_cfg_w_i_7  }   -side 1 -order 23
set_pad_physical_constraints -pad_name { I1025_cfg_w_i_8  }   -side 1 -order 24

set_pad_physical_constraints -pad_name { I1025_val_i      }   -side 1 -order 25

# 2: top
set_pad_physical_constraints -pad_name { I1025_dat_i_0    }   -side 2 -order 1
set_pad_physical_constraints -pad_name { I1025_dat_i_1    }   -side 2 -order 2
set_pad_physical_constraints -pad_name { I1025_dat_i_2    }   -side 2 -order 3
set_pad_physical_constraints -pad_name { I1025_dat_i_3    }   -side 2 -order 4
set_pad_physical_constraints -pad_name { I1025_dat_i_4    }   -side 2 -order 5
set_pad_physical_constraints -pad_name { I1025_dat_i_5    }   -side 2 -order 6
set_pad_physical_constraints -pad_name { I1025_dat_i_6    }   -side 2 -order 7
set_pad_physical_constraints -pad_name { I1025_dat_i_7    }   -side 2 -order 8
set_pad_physical_constraints -pad_name { I1025_dat_i_8    }   -side 2 -order 9
set_pad_physical_constraints -pad_name { I1025_dat_i_9    }   -side 2 -order 10
set_pad_physical_constraints -pad_name { I1025_dat_i_10   }   -side 2 -order 11

set_pad_physical_constraints -pad_name { vdd_t            }   -side 2 -order 12
set_pad_physical_constraints -pad_name { vss_t            }   -side 2 -order 13
set_pad_physical_constraints -pad_name { io_vss_t         }   -side 2 -order 14

set_pad_physical_constraints -pad_name { I1025_dat_i_11   }   -side 2 -order 15
set_pad_physical_constraints -pad_name { I1025_dat_i_12   }   -side 2 -order 16
set_pad_physical_constraints -pad_name { I1025_dat_i_13   }   -side 2 -order 17
set_pad_physical_constraints -pad_name { I1025_dat_i_14   }   -side 2 -order 18
set_pad_physical_constraints -pad_name { I1025_dat_i_15   }   -side 2 -order 19
set_pad_physical_constraints -pad_name { I1025_dat_i_16   }   -side 2 -order 20
set_pad_physical_constraints -pad_name { I1025_dat_i_17   }   -side 2 -order 21
set_pad_physical_constraints -pad_name { I1025_dat_i_18   }   -side 2 -order 22
set_pad_physical_constraints -pad_name { I1025_dat_i_19   }   -side 2 -order 23
set_pad_physical_constraints -pad_name { I1025_dat_i_20   }   -side 2 -order 24
set_pad_physical_constraints -pad_name { I1025_dat_i_21   }   -side 2 -order 25

# 3: right
set_pad_physical_constraints -pad_name { I1025_dat_i_22   }   -side 3 -order 25
set_pad_physical_constraints -pad_name { I1025_dat_i_23   }   -side 3 -order 24
set_pad_physical_constraints -pad_name { I1025_dat_i_24   }   -side 3 -order 23
set_pad_physical_constraints -pad_name { I1025_dat_i_25   }   -side 3 -order 22
set_pad_physical_constraints -pad_name { I1025_dat_i_26   }   -side 3 -order 21
set_pad_physical_constraints -pad_name { I1025_dat_i_27   }   -side 3 -order 20
set_pad_physical_constraints -pad_name { I1025_dat_i_28   }   -side 3 -order 19
set_pad_physical_constraints -pad_name { I1025_dat_i_29   }   -side 3 -order 18
set_pad_physical_constraints -pad_name { I1025_dat_i_30   }   -side 3 -order 17
set_pad_physical_constraints -pad_name { I1025_dat_i_31   }   -side 3 -order 16


set_pad_physical_constraints -pad_name { io_vdd_r         }   -side 3 -order 15
set_pad_physical_constraints -pad_name { vdd_r            }   -side 3 -order 14
set_pad_physical_constraints -pad_name { vss_r            }   -side 3 -order 13

set_pad_physical_constraints -pad_name { B12I1025_done_o  }   -side 3 -order 12
set_pad_physical_constraints -pad_name { B12I1025_val_o   }   -side 3 -order 11

set_pad_physical_constraints -pad_name { B12I1025_dat_o_0 }   -side 3 -order 10
set_pad_physical_constraints -pad_name { B12I1025_dat_o_1 }   -side 3 -order 9
set_pad_physical_constraints -pad_name { B12I1025_dat_o_2 }   -side 3 -order 8
set_pad_physical_constraints -pad_name { B12I1025_dat_o_3 }   -side 3 -order 7
set_pad_physical_constraints -pad_name { B12I1025_dat_o_4 }   -side 3 -order 6
set_pad_physical_constraints -pad_name { B12I1025_dat_o_5 }   -side 3 -order 5
set_pad_physical_constraints -pad_name { B12I1025_dat_o_6 }   -side 3 -order 4
set_pad_physical_constraints -pad_name { B12I1025_dat_o_7 }   -side 3 -order 3
set_pad_physical_constraints -pad_name { B12I1025_dat_o_8 }   -side 3 -order 2
set_pad_physical_constraints -pad_name { B12I1025_dat_o_9 }   -side 3 -order 1

# 4: bottom
set_pad_physical_constraints -pad_name { B12I1025_dat_o_10 }   -side 4 -order 25
set_pad_physical_constraints -pad_name { B12I1025_dat_o_11 }   -side 4 -order 24
set_pad_physical_constraints -pad_name { B12I1025_dat_o_12 }   -side 4 -order 23
set_pad_physical_constraints -pad_name { B12I1025_dat_o_13 }   -side 4 -order 22
set_pad_physical_constraints -pad_name { B12I1025_dat_o_14 }   -side 4 -order 21
set_pad_physical_constraints -pad_name { B12I1025_dat_o_15 }   -side 4 -order 20
set_pad_physical_constraints -pad_name { B12I1025_dat_o_16 }   -side 4 -order 19
set_pad_physical_constraints -pad_name { B12I1025_dat_o_17 }   -side 4 -order 18
set_pad_physical_constraints -pad_name { B12I1025_dat_o_18 }   -side 4 -order 17
set_pad_physical_constraints -pad_name { B12I1025_dat_o_19 }   -side 4 -order 16
set_pad_physical_constraints -pad_name { B12I1025_dat_o_20 }   -side 4 -order 15

set_pad_physical_constraints -pad_name { io_vss_b          }   -side 4 -order 14
set_pad_physical_constraints -pad_name { vss_b             }   -side 4 -order 13
set_pad_physical_constraints -pad_name { vdd_b             }   -side 4 -order 12

set_pad_physical_constraints -pad_name { B12I1025_dat_o_21 }   -side 4 -order 11
set_pad_physical_constraints -pad_name { B12I1025_dat_o_22 }   -side 4 -order 10
set_pad_physical_constraints -pad_name { B12I1025_dat_o_23 }   -side 4 -order 9
set_pad_physical_constraints -pad_name { B12I1025_dat_o_24 }   -side 4 -order 8
set_pad_physical_constraints -pad_name { B12I1025_dat_o_25 }   -side 4 -order 7
set_pad_physical_constraints -pad_name { B12I1025_dat_o_26 }   -side 4 -order 6
set_pad_physical_constraints -pad_name { B12I1025_dat_o_27 }   -side 4 -order 5
set_pad_physical_constraints -pad_name { B12I1025_dat_o_28 }   -side 4 -order 4
set_pad_physical_constraints -pad_name { B12I1025_dat_o_29 }   -side 4 -order 3
set_pad_physical_constraints -pad_name { B12I1025_dat_o_30 }   -side 4 -order 2
set_pad_physical_constraints -pad_name { B12I1025_dat_o_31 }   -side 4 -order 1
