# ---    io   -----------------------------------------------------------------

# side:
#            2 
#         1     3
#            4

# order:
#    1 2 3
#    ---------------------------------------------->
#    ^                dat_i[0-21]                  ^
#    |  val_i                        dat_i[22-31]  |
#    |  cfg_h[0-8]                   done          |
#    |  cfg_w[0-8]                   val_o         |
#    |  start                        dat_o[0-9]    |
#    |  rst                          io[vdd_r      |
#  3 |  clk                                        | 3
#  2 |                                             | 2
#  1 |                dat_o[31-10]                 | 1
#    ---------------------------------------------->
#    1 2 3


# 1: left
set_pin_physical_constraints -pin_name { clk        }  -side 1 -order 1
set_pin_physical_constraints -pin_name { rstn       }  -side 1 -order 2
set_pin_physical_constraints -pin_name { start_i    }  -side 1 -order 3

set_pin_physical_constraints -pin_name { cfg_h_i[0]  }  -side 1 -order 4
set_pin_physical_constraints -pin_name { cfg_h_i[1]  }  -side 1 -order 5
set_pin_physical_constraints -pin_name { cfg_h_i[2]  }  -side 1 -order 6
set_pin_physical_constraints -pin_name { cfg_h_i[3]  }  -side 1 -order 7
set_pin_physical_constraints -pin_name { cfg_h_i[4]  }  -side 1 -order 8
set_pin_physical_constraints -pin_name { cfg_h_i[5]  }  -side 1 -order 9
set_pin_physical_constraints -pin_name { cfg_h_i[6]  }  -side 1 -order 10
set_pin_physical_constraints -pin_name { cfg_h_i[7]  }  -side 1 -order 11
set_pin_physical_constraints -pin_name { cfg_h_i[8]  }  -side 1 -order 12
set_pin_physical_constraints -pin_name { cfg_w_i[0]  }  -side 1 -order 13
set_pin_physical_constraints -pin_name { cfg_w_i[1]  }  -side 1 -order 14
set_pin_physical_constraints -pin_name { cfg_w_i[2]  }  -side 1 -order 15
set_pin_physical_constraints -pin_name { cfg_w_i[3]  }  -side 1 -order 16
set_pin_physical_constraints -pin_name { cfg_w_i[4]  }  -side 1 -order 17
set_pin_physical_constraints -pin_name { cfg_w_i[5]  }  -side 1 -order 18
set_pin_physical_constraints -pin_name { cfg_w_i[6]  }  -side 1 -order 19
set_pin_physical_constraints -pin_name { cfg_w_i[7]  }  -side 1 -order 20
set_pin_physical_constraints -pin_name { cfg_w_i[8]  }  -side 1 -order 21
set_pin_physical_constraints -pin_name { val_i      }  -side 1 -order 22

# 2: top
set_pin_physical_constraints -pin_name { dat_i[0]    }  -side 2 -order 1
set_pin_physical_constraints -pin_name { dat_i[1]    }  -side 2 -order 2
set_pin_physical_constraints -pin_name { dat_i[2]    }  -side 2 -order 3
set_pin_physical_constraints -pin_name { dat_i[3]    }  -side 2 -order 4
set_pin_physical_constraints -pin_name { dat_i[4]    }  -side 2 -order 5
set_pin_physical_constraints -pin_name { dat_i[5]    }  -side 2 -order 6
set_pin_physical_constraints -pin_name { dat_i[6]    }  -side 2 -order 7
set_pin_physical_constraints -pin_name { dat_i[7]    }  -side 2 -order 8
set_pin_physical_constraints -pin_name { dat_i[8]    }  -side 2 -order 9
set_pin_physical_constraints -pin_name { dat_i[9]    }  -side 2 -order 10
set_pin_physical_constraints -pin_name { dat_i[10]   }  -side 2 -order 11
set_pin_physical_constraints -pin_name { dat_i[11]   }  -side 2 -order 12
set_pin_physical_constraints -pin_name { dat_i[12]   }  -side 2 -order 13
set_pin_physical_constraints -pin_name { dat_i[13]   }  -side 2 -order 14
set_pin_physical_constraints -pin_name { dat_i[14]   }  -side 2 -order 15
set_pin_physical_constraints -pin_name { dat_i[15]   }  -side 2 -order 16
set_pin_physical_constraints -pin_name { dat_i[16]   }  -side 2 -order 17
set_pin_physical_constraints -pin_name { dat_i[17]   }  -side 2 -order 18
set_pin_physical_constraints -pin_name { dat_i[18]   }  -side 2 -order 19
set_pin_physical_constraints -pin_name { dat_i[19]   }  -side 2 -order 20
set_pin_physical_constraints -pin_name { dat_i[20]   }  -side 2 -order 21
set_pin_physical_constraints -pin_name { dat_i[21]   }  -side 2 -order 22

# 3: right
set_pin_physical_constraints -pin_name { dat_i[22]   }  -side 3 -order 22
set_pin_physical_constraints -pin_name { dat_i[23]   }  -side 3 -order 21
set_pin_physical_constraints -pin_name { dat_i[24]   }  -side 3 -order 20
set_pin_physical_constraints -pin_name { dat_i[25]   }  -side 3 -order 19
set_pin_physical_constraints -pin_name { dat_i[26]   }  -side 3 -order 18
set_pin_physical_constraints -pin_name { dat_i[27]   }  -side 3 -order 27
set_pin_physical_constraints -pin_name { dat_i[28]   }  -side 3 -order 16
set_pin_physical_constraints -pin_name { dat_i[29]   }  -side 3 -order 15
set_pin_physical_constraints -pin_name { dat_i[30]   }  -side 3 -order 14
set_pin_physical_constraints -pin_name { dat_i[31]   }  -side 3 -order 13

set_pin_physical_constraints -pin_name { done_o     }  -side 3 -order 12
set_pin_physical_constraints -pin_name { val_o      }  -side 3 -order 11

set_pin_physical_constraints -pin_name { dat_o[0]    }  -side 3 -order 10
set_pin_physical_constraints -pin_name { dat_o[1]    }  -side 3 -order 9
set_pin_physical_constraints -pin_name { dat_o[2]    }  -side 3 -order 8
set_pin_physical_constraints -pin_name { dat_o[3]    }  -side 3 -order 7
set_pin_physical_constraints -pin_name { dat_o[4]    }  -side 3 -order 6
set_pin_physical_constraints -pin_name { dat_o[5]    }  -side 3 -order 5
set_pin_physical_constraints -pin_name { dat_o[6]    }  -side 3 -order 4
set_pin_physical_constraints -pin_name { dat_o[7]    }  -side 3 -order 3
set_pin_physical_constraints -pin_name { dat_o[8]    }  -side 3 -order 2
set_pin_physical_constraints -pin_name { dat_o[9]    }  -side 3 -order 1

# 4: bottom
set_pin_physical_constraints -pin_name { dat_o[10]   }  -side 4 -order 22
set_pin_physical_constraints -pin_name { dat_o[11]   }  -side 4 -order 21
set_pin_physical_constraints -pin_name { dat_o[12]   }  -side 4 -order 20
set_pin_physical_constraints -pin_name { dat_o[13]   }  -side 4 -order 19
set_pin_physical_constraints -pin_name { dat_o[14]   }  -side 4 -order 18
set_pin_physical_constraints -pin_name { dat_o[15]   }  -side 4 -order 17
set_pin_physical_constraints -pin_name { dat_o[16]   }  -side 4 -order 16
set_pin_physical_constraints -pin_name { dat_o[17]   }  -side 4 -order 15
set_pin_physical_constraints -pin_name { dat_o[18]   }  -side 4 -order 14
set_pin_physical_constraints -pin_name { dat_o[19]   }  -side 4 -order 13
set_pin_physical_constraints -pin_name { dat_o[20]   }  -side 4 -order 12
set_pin_physical_constraints -pin_name { dat_o[21]   }  -side 4 -order 11
set_pin_physical_constraints -pin_name { dat_o[22]   }  -side 4 -order 10
set_pin_physical_constraints -pin_name { dat_o[23]   }  -side 4 -order 9
set_pin_physical_constraints -pin_name { dat_o[24]   }  -side 4 -order 8
set_pin_physical_constraints -pin_name { dat_o[25]   }  -side 4 -order 7
set_pin_physical_constraints -pin_name { dat_o[26]   }  -side 4 -order 6
set_pin_physical_constraints -pin_name { dat_o[27]   }  -side 4 -order 5
set_pin_physical_constraints -pin_name { dat_o[28]   }  -side 4 -order 4
set_pin_physical_constraints -pin_name { dat_o[29]   }  -side 4 -order 3
set_pin_physical_constraints -pin_name { dat_o[30]   }  -side 4 -order 2
set_pin_physical_constraints -pin_name { dat_o[31]   }  -side 4 -order 1
