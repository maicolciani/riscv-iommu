// Copyright © 2023 Manuel Rodríguez & Zero-Day Labs, Lda.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// Licensed under the Solderpad Hardware License v 2.1 (the “License”); 
// you may not use this file except in compliance with the License, 
// or, at your option, the Apache License version 2.0. 
// You may obtain a copy of the License at https://solderpad.org/licenses/SHL-2.1/.
// Unless required by applicable law or agreed to in writing, 
// any work distributed under the License is distributed on an “AS IS” BASIS, 
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
// See the License for the specific language governing permissions and limitations under the License.
//
// Author: Manuel Rodríguez <manuel.cederog@gmail.com>
// Date: 13/10/2022
//
// Description: IOMMU memory-mapped register interface package.
//              Defines data structures and other register-related data.
//
// Disclaimer:  This file was generated using LowRISC `reggen` tool. Edit at your own risk.


`include "include/assertions.svh"
`include "packages/iommu_reg_pkg_exp.sv"
`include "packages/iommu_field_pkg.sv"
`include "include/typedef_reg.svh"
`include "include/typedef_global.svh"

module iommu_regmap_wrapper #(
    parameter int 			ADDR_WIDTH = 64,
    parameter int 			DATA_WIDTH = 64,
    parameter type 			reg_req_t = logic,
    parameter type 			reg_rsp_t = logic,
	  parameter int unsigned 	STRB_WIDTH = (DATA_WIDTH / 8)
) (
	input logic clk_i,
	input logic rst_ni,
	// From SW
	input  reg_req_t 						reg_req_i,
	output reg_rsp_t 						reg_rsp_o,
	// To HW
	output iommu_reg_pkg::iommu_reg2hw_t 	reg2hw, // Write
	input  iommu_reg_pkg::iommu_hw2reg_t 	hw2reg, // Read

	// Config
	input logic devmode_i // If 1, explicit error return for unmapped register access
);

  import iommu_reg_pkg::* ;
  import iommu_field_pkg::* ;

  // register signals
  // EXP: Register signals to connect the SW register interface port to the register file.
  logic           			reg_we;
  logic           			reg_re;
  logic [ADDR_WIDTH-1:0]  	reg_addr;
  logic [DATA_WIDTH-1:0]  	reg_wdata;
  logic [STRB_WIDTH-1:0] 	reg_be;
  logic [DATA_WIDTH-1:0]  	reg_rdata;
  logic           			reg_error;
  logic           			reg_ready;

  logic addrmiss, wr_err;
  logic [DATA_WIDTH-1:0] reg_rdata_next;

  reg_req_t  reg_intf_req;
  reg_rsp_t  reg_intf_rsp;


  assign reg_intf_req = reg_req_i;
  assign reg_rsp_o = reg_intf_rsp;


  assign reg_we = reg_intf_req.valid & reg_intf_req.write;
  assign reg_re = reg_intf_req.valid & ~reg_intf_req.write;
  assign reg_addr = reg_intf_req.addr[11:0];	// only compare the offsets. Regmap is 4kiB alligned.
  assign reg_wdata = reg_intf_req.wdata;
  assign reg_be = reg_intf_req.wstrb;
  assign reg_intf_rsp.rdata = reg_rdata;
  assign reg_intf_rsp.error = reg_error;
  // assign reg_intf_rsp.ready = reg_we | reg_re;
  assign reg_intf_rsp.ready = 1'b1;

  assign reg_rdata = reg_re ? reg_rdata_next : '0;
  assign reg_error = (devmode_i & addrmiss) | wr_err;   // when in development mode, address misses are not silent


  // Define SW related signals
  // Format: <reg>_<field>_{wd|we|qs}
  //        or <reg>_{wd|we|qs} if field == 1 or 0
  //
  // EXP: qs signals are connected from the registers (those that can be read from SW);

  // caps
  logic [7:0] 	capabilities_version_qs;
  logic 		capabilities_sv32_qs;
  logic 		capabilities_sv39_qs;
  logic 		capabilities_sv48_qs;
  logic 		capabilities_sv57_qs;
  logic 		capabilities_svpbmt_qs;
  logic 		capabilities_sv32x4_qs;
  logic 		capabilities_sv39x4_qs;
  logic 		capabilities_sv48x4_qs;
  logic 		capabilities_sv57x4_qs;
  logic 		capabilities_msi_flat_qs;
  logic 		capabilities_msi_mrif_qs;
  logic 		capabilities_amo_qs;
  logic 		capabilities_ats_qs;
  logic 		capabilities_t2gpa_qs;
  logic 		capabilities_endi_qs;
  logic [1:0] 	capabilities_igs_qs;
  logic 		capabilities_hpm_qs;
  logic 		capabilities_dbg_qs;
  logic [5:0] 	capabilities_pas_qs;
  logic 		capabilities_pd8_qs;
  logic 		capabilities_pd17_qs;
  logic 		capabilities_pd20_qs;

  // fctl
  logic 		fctl_be_qs;
//   logic fctl_be_wd;
//   logic fctl_be_we;
  logic 		fctl_wsi_qs;
  logic 		fctl_wsi_wd;
  logic 		fctl_wsi_we;
  logic 		fctl_glx_qs;
  logic 		fctl_glx_wd;
  logic 		fctl_glx_we;

  // ddtp
  logic [3:0] 	ddtp_iommu_mode_qs;
  logic [3:0] 	ddtp_iommu_mode_wd;
  logic 		ddtp_iommu_mode_we;
  logic 		ddtp_busy_qs;
  logic [43:0] 	ddtp_ppn_qs;
  logic [43:0] 	ddtp_ppn_wd;
  logic 		ddtp_ppn_we;

  // cqb
  logic [4:0] 	cqb_log2sz_1_qs;
  logic [4:0] 	cqb_log2sz_1_wd;
  logic 		cqb_log2sz_1_we;
  logic [43:0] 	cqb_ppn_qs;
  logic [43:0] 	cqb_ppn_wd;
  logic 		cqb_ppn_we;

  // cqh
  logic [31:0] 	cqh_qs;

  // cqt
  logic [31:0] 	cqt_qs;
  logic [31:0] 	cqt_wd;
  logic cqt_we;

  // fqb
  logic [4:0] 	fqb_log2sz_1_qs;
  logic [4:0] 	fqb_log2sz_1_wd;
  logic 		fqb_log2sz_1_we;
  logic [43:0] 	fqb_ppn_qs;
  logic [43:0] 	fqb_ppn_wd;
  logic 		fqb_ppn_we;

  // fqh
  logic [31:0] 	fqh_qs;
  logic [31:0] 	fqh_wd;
  logic fqh_we;

  // fqt
  logic [31:0] 	fqt_qs;

  // cqcsr
  logic 		cqcsr_cqen_qs;
  logic 		cqcsr_cqen_wd;
  logic 		cqcsr_cqen_we;
  logic 		cqcsr_cie_qs;
  logic 		cqcsr_cie_wd;
  logic 		cqcsr_cie_we;
  logic 		cqcsr_cqmf_qs;
  logic 		cqcsr_cqmf_wd;
  logic 		cqcsr_cqmf_we;
  logic 		cqcsr_cmd_to_qs;
  logic 		cqcsr_cmd_to_wd;
  logic 		cqcsr_cmd_to_we;
  logic 		cqcsr_cmd_ill_qs;
  logic 		cqcsr_cmd_ill_wd;
  logic 		cqcsr_cmd_ill_we;
  logic 		cqcsr_fence_w_ip_qs;
  logic 		cqcsr_fence_w_ip_wd;
  logic 		cqcsr_fence_w_ip_we;
  logic 		cqcsr_cqon_qs;
  logic 		cqcsr_busy_qs;

  // fqcsr
  logic 		fqcsr_fqen_qs;
  logic 		fqcsr_fqen_wd;
  logic 		fqcsr_fqen_we;
  logic 		fqcsr_fie_qs;
  logic 		fqcsr_fie_wd;
  logic 		fqcsr_fie_we;
  logic 		fqcsr_fqmf_qs;
  logic 		fqcsr_fqmf_wd;
  logic 		fqcsr_fqmf_we;
  logic 		fqcsr_fqof_qs;
  logic 		fqcsr_fqof_wd;
  logic 		fqcsr_fqof_we;
  logic 		fqcsr_fqon_qs;
  logic 		fqcsr_busy_qs;

  // ipsr
  logic 		ipsr_cip_qs;
  logic 		ipsr_cip_wd;
  logic 		ipsr_cip_we;
  logic 		ipsr_fip_qs;
  logic 		ipsr_fip_wd;
  logic 		ipsr_fip_we;
  logic 		ipsr_pmip_qs;
  logic 		ipsr_pmip_wd;
  logic 		ipsr_pmip_we;
  logic 		ipsr_pip_qs;
  logic 		ipsr_pip_wd;
  logic 		ipsr_pip_we;

  // icvec
  logic [3:0] 	icvec_civ_qs;
  logic [3:0] 	icvec_civ_wd;
  logic 		icvec_civ_we;
  logic [3:0] 	icvec_fiv_qs;
  logic [3:0] 	icvec_fiv_wd;
  logic 		icvec_fiv_we;
  logic [3:0] 	icvec_pmiv_qs;
  logic [3:0] 	icvec_pmiv_wd;
  logic 		icvec_pmiv_we;
  logic [3:0] 	icvec_piv_qs;
  logic [3:0] 	icvec_piv_wd;
  logic 		icvec_piv_we;

  // MSI configuration table
  logic [53:0] msi_addr_0_addr_qs;
  logic [53:0] msi_addr_0_addr_wd;
  logic msi_addr_0_addr_we;
  logic [31:0] msi_data_0_qs;
  logic [31:0] msi_data_0_wd;
  logic msi_data_0_we;
  logic msi_vec_ctl_0_qs;
  logic msi_vec_ctl_0_wd;
  logic msi_vec_ctl_0_we;

  logic [53:0] msi_addr_1_addr_qs;
  logic [53:0] msi_addr_1_addr_wd;
  logic msi_addr_1_addr_we;
  logic [31:0] msi_data_1_qs;
  logic [31:0] msi_data_1_wd;
  logic msi_data_1_we;
  logic msi_vec_ctl_1_qs;
  logic msi_vec_ctl_1_wd;
  logic msi_vec_ctl_1_we;

  logic [53:0] msi_addr_2_addr_qs;
  logic [53:0] msi_addr_2_addr_wd;
  logic msi_addr_2_addr_we;
  logic [31:0] msi_data_2_qs;
  logic [31:0] msi_data_2_wd;
  logic msi_data_2_we;
  logic msi_vec_ctl_2_qs;
  logic msi_vec_ctl_2_wd;
  logic msi_vec_ctl_2_we;

  logic [53:0] msi_addr_3_addr_qs;
  logic [53:0] msi_addr_3_addr_wd;
  logic msi_addr_3_addr_we;
  logic [31:0] msi_data_3_qs;
  logic [31:0] msi_data_3_wd;
  logic msi_data_3_we;
  logic msi_vec_ctl_3_qs;
  logic msi_vec_ctl_3_wd;
  logic msi_vec_ctl_3_we;

  logic [53:0] msi_addr_4_addr_qs;
  logic [53:0] msi_addr_4_addr_wd;
  logic msi_addr_4_addr_we;
  logic [31:0] msi_data_4_qs;
  logic [31:0] msi_data_4_wd;
  logic msi_data_4_we;
  logic msi_vec_ctl_4_qs;
  logic msi_vec_ctl_4_wd;
  logic msi_vec_ctl_4_we;

  logic [53:0] msi_addr_5_addr_qs;
  logic [53:0] msi_addr_5_addr_wd;
  logic msi_addr_5_addr_we;
  logic [31:0] msi_data_5_qs;
  logic [31:0] msi_data_5_wd;
  logic msi_data_5_we;
  logic msi_vec_ctl_5_qs;
  logic msi_vec_ctl_5_wd;
  logic msi_vec_ctl_5_we;

  logic [53:0] msi_addr_6_addr_qs;
  logic [53:0] msi_addr_6_addr_wd;
  logic msi_addr_6_addr_we;
  logic [31:0] msi_data_6_qs;
  logic [31:0] msi_data_6_wd;
  logic msi_data_6_we;
  logic msi_vec_ctl_6_qs;
  logic msi_vec_ctl_6_wd;
  logic msi_vec_ctl_6_we;

  logic [53:0] msi_addr_7_addr_qs;
  logic [53:0] msi_addr_7_addr_wd;
  logic msi_addr_7_addr_we;
  logic [31:0] msi_data_7_qs;
  logic [31:0] msi_data_7_wd;
  logic msi_data_7_we;
  logic msi_vec_ctl_7_qs;
  logic msi_vec_ctl_7_wd;
  logic msi_vec_ctl_7_we;

  logic [53:0] msi_addr_8_addr_qs;
  logic [53:0] msi_addr_8_addr_wd;
  logic msi_addr_8_addr_we;
  logic [31:0] msi_data_8_qs;
  logic [31:0] msi_data_8_wd;
  logic msi_data_8_we;
  logic msi_vec_ctl_8_qs;
  logic msi_vec_ctl_8_wd;
  logic msi_vec_ctl_8_we;

  logic [53:0] msi_addr_9_addr_qs;
  logic [53:0] msi_addr_9_addr_wd;
  logic msi_addr_9_addr_we;
  logic [31:0] msi_data_9_qs;
  logic [31:0] msi_data_9_wd;
  logic msi_data_9_we;
  logic msi_vec_ctl_9_qs;
  logic msi_vec_ctl_9_wd;
  logic msi_vec_ctl_9_we;

  logic [53:0] msi_addr_10_addr_qs;
  logic [53:0] msi_addr_10_addr_wd;
  logic msi_addr_10_addr_we;
  logic [31:0] msi_data_10_qs;
  logic [31:0] msi_data_10_wd;
  logic msi_data_10_we;
  logic msi_vec_ctl_10_qs;
  logic msi_vec_ctl_10_wd;
  logic msi_vec_ctl_10_we;

  logic [53:0] msi_addr_11_addr_qs;
  logic [53:0] msi_addr_11_addr_wd;
  logic msi_addr_11_addr_we;
  logic [31:0] msi_data_11_qs;
  logic [31:0] msi_data_11_wd;
  logic msi_data_11_we;
  logic msi_vec_ctl_11_qs;
  logic msi_vec_ctl_11_wd;
  logic msi_vec_ctl_11_we;

  logic [53:0] msi_addr_12_addr_qs;
  logic [53:0] msi_addr_12_addr_wd;
  logic msi_addr_12_addr_we;
  logic [31:0] msi_data_12_qs;
  logic [31:0] msi_data_12_wd;
  logic msi_data_12_we;
  logic msi_vec_ctl_12_qs;
  logic msi_vec_ctl_12_wd;
  logic msi_vec_ctl_12_we;

  logic [53:0] msi_addr_13_addr_qs;
  logic [53:0] msi_addr_13_addr_wd;
  logic msi_addr_13_addr_we;
  logic [31:0] msi_data_13_qs;
  logic [31:0] msi_data_13_wd;
  logic msi_data_13_we;
  logic msi_vec_ctl_13_qs;
  logic msi_vec_ctl_13_wd;
  logic msi_vec_ctl_13_we;

  logic [53:0] msi_addr_14_addr_qs;
  logic [53:0] msi_addr_14_addr_wd;
  logic msi_addr_14_addr_we;
  logic [31:0] msi_data_14_qs;
  logic [31:0] msi_data_14_wd;
  logic msi_data_14_we;
  logic msi_vec_ctl_14_qs;
  logic msi_vec_ctl_14_wd;
  logic msi_vec_ctl_14_we;

  logic [53:0] msi_addr_15_addr_qs;
  logic [53:0] msi_addr_15_addr_wd;
  logic msi_addr_15_addr_we;
  logic [31:0] msi_data_15_qs;
  logic [31:0] msi_data_15_wd;
  logic msi_data_15_we;
  logic msi_vec_ctl_15_qs;
  logic msi_vec_ctl_15_wd;
  logic msi_vec_ctl_15_we;

  //# Register instances
  // R[capabilities]: V(False)

  //   F[version]: 7:0
  // Hardwired register containing the version of the specification implemented by the IOMMU

  // iommu_field #(
  //   .DATA_WIDTH      (8),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (8'h10)
  // ) u_capabilities_version (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      (8'h10  ),  // harDATA_WIDTHire to 0x10

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.version.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_version_qs)
  // );
  assign reg2hw.capabilities.version.q = 8'h10; // for internal HW reads
  assign capabilities_version_qs = 8'h10;       // for SW reads


  //   F[sv32]: 8:8
  // Sv32 should be supported by this implementation
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h1)
  // ) u_capabilities_sv32 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('1  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.sv32.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_sv32_qs)
  // );
  assign reg2hw.capabilities.sv32.q = 1'h0;
  assign capabilities_sv32_qs = 1'h0;


  //   F[sv39]: 9:9
  // Sv39 should be supported by this implementation
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h1)
  // ) u_capabilities_sv39 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('1  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.sv39.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_sv39_qs)
  // );
  assign reg2hw.capabilities.sv39.q = 1'h1;
  assign capabilities_sv39_qs = 1'h1;

  //   F[sv48]: 10:10
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_sv48 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.sv48.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_sv48_qs)
  // );
  assign reg2hw.capabilities.sv48.q = 1'h0;
  assign capabilities_sv48_qs = 1'h0;


  //   F[sv57]: 11:11
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_sv57 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.sv57.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_sv57_qs)
  // );
  assign reg2hw.capabilities.sv57.q = 1'h0;
  assign capabilities_sv57_qs = 1'h0;


  //   F[svpbmt]: 15:15
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_svpbmt (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.svpbmt.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_svpbmt_qs)
  // );
  assign reg2hw.capabilities.svpbmt.q = 1'h0;
  assign capabilities_svpbmt_qs = 1'h0;


  //   F[sv32x4]: 16:16
  // For G-stage translation
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h1)
  // ) u_capabilities_sv32x4 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('1  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.sv32x4.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_sv32x4_qs)
  // );
  assign reg2hw.capabilities.sv32x4.q = 1'h0;
  assign capabilities_sv32x4_qs = 1'h0;


  //   F[sv39x4]: 17:17
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h1)
  // ) u_capabilities_sv39x4 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('1  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.sv39x4.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_sv39x4_qs)
  // );
  assign reg2hw.capabilities.sv39x4.q = 1'h1;
  assign capabilities_sv39x4_qs = 1'h1;


  //   F[sv48x4]: 18:18
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_sv48x4 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.sv48x4.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_sv48x4_qs)
  // );
  assign reg2hw.capabilities.sv48x4.q = 1'h0;
  assign capabilities_sv48x4_qs = 1'h0;


  //   F[sv57x4]: 19:19
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_sv57x4 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.sv57x4.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_sv57x4_qs)
  // );
  assign reg2hw.capabilities.sv57x4.q = 1'h0;
  assign capabilities_sv57x4_qs = 1'h0;

  //   F[msi_flat]: 22:22
  // MSI redirection to Guest interrupt files must be implemented to give support to AIA
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h1)
  // ) u_capabilities_msi_flat (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('1  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.msi_flat.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_msi_flat_qs)
  // );
  assign reg2hw.capabilities.msi_flat.q = 1'h1;
  assign capabilities_msi_flat_qs = 1'h1;


  //   F[msi_mrif]: 23:23
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_msi_mrif (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.msi_mrif.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_msi_mrif_qs)
  // );
  assign reg2hw.capabilities.msi_mrif.q = 1'h0;
  assign capabilities_msi_mrif_qs = 1'h0;


  //   F[amo]: 24:24
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_amo (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.amo.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_amo_qs)
  // );
  assign reg2hw.capabilities.amo.q = 1'h0;
  assign capabilities_amo_qs = 1'h0;


  //   F[ats]: 25:25
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_ats (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.ats.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_ats_qs)
  // );
  assign reg2hw.capabilities.ats.q = 1'h0;
  assign capabilities_ats_qs = 1'h0;


  //   F[t2gpa]: 26:26
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_t2gpa (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.t2gpa.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_t2gpa_qs)
  // );
  assign reg2hw.capabilities.t2gpa.q = 1'h0;
  assign capabilities_t2gpa_qs = 1'h0;


  //   F[endi]: 27:27
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_endi (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.endi.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_endi_qs)
  // );
  assign reg2hw.capabilities.endi.q = 1'h0;
  assign capabilities_endi_qs = 1'h0;


  //   F[igs]: 29:28
  // iommu_field #(
  //   .DATA_WIDTH      (2),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (2'h0)
  // ) u_capabilities_igs (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.igs.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_igs_qs)
  // );
  assign reg2hw.capabilities.igs.q = 2'h0;
  assign capabilities_igs_qs = 2'h0;


  //   F[hpm]: 30:30
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_hpm (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.hpm.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_hpm_qs)
  // );
  assign reg2hw.capabilities.hpm.q = 1'h0;
  assign capabilities_hpm_qs = 1'h0;


  //   F[dbg]: 31:31
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_dbg (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.dbg.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_dbg_qs)
  // );
  assign reg2hw.capabilities.dbg.q = 1'h0;
  assign capabilities_dbg_qs = 1'h0;


  //   F[pas]: 37:32
  // iommu_field #(
  //   .DATA_WIDTH      (6),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (6'h22)          // Physical Address Size reset value of 34 for Sv32
  // ) u_capabilities_pas (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      (6'h22  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.pas.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_pas_qs)
  // );
  assign reg2hw.capabilities.pas.q = 6'h38;
  assign capabilities_pas_qs = 6'h38;


  //   F[pd8]: 38:38
  // One level PDT with 8-bit process_id by default
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h1)
  // ) u_capabilities_pd8 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('1  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.pd8.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_pd8_qs)
  // );
  assign reg2hw.capabilities.pd8.q = 1'h1;
  assign capabilities_pd8_qs = 1'h1;


  //   F[pd17]: 39:39
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_pd17 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.pd17.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_pd17_qs)
  // );
  assign reg2hw.capabilities.pd17.q = 1'h1;
  assign capabilities_pd17_qs = 1'h1;


  //   F[pd20]: 40:40
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessRO),
  //   .RESVAL  (1'h0)
  // ) u_capabilities_pd20 (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   .we     (1'b0),
  //   .wd     ('0  ),

  //   // from internal hardware
  //   .de     (1'b1),
  //   .d      ('0  ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.capabilities.pd20.q ),

  //   // to register interface (read)
  //   .qs     (capabilities_pd20_qs)
  // );
  assign reg2hw.capabilities.pd20.q = 1'h1;
  assign capabilities_pd20_qs = 1'h1;


  // R[fctl]: V(False)

  //   F[be]: 0:0
//   iommu_field #(
//     .DATA_WIDTH      (1),
//     .SwAccess(SwAccessRW),
//     .RESVAL  (1'h0)
//   ) u_fctl_be (
//     .clk_i   (clk_i    ),
//     .rst_ni  (rst_ni  ),

//     // from register interface
//     .we     (fctl_be_we),
//     .wd     (fctl_be_wd),

//     // from internal hardware
//     .de     (hw2reg.fctl.be.de),
//     .ds     (),
//     .d      (hw2reg.fctl.be.d ),

//     // to internal hardware
//     .qe     (),
//     .q      (reg2hw.fctl.be.q ),

//     // to register interface (read)
//     .qs     (fctl_be_qs)
//   );
	assign fctl_be_qs	= 1'b0;


  //   F[wsi]: 1:1
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_fctl_wsi (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (fctl_wsi_we),
    .wd     (fctl_wsi_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fctl.wsi.q ),

    // to register interface (read)
    .qs     (fctl_wsi_qs)
  );


  //   F[glx]: 2:2
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_fctl_glx (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (fctl_glx_we),
    .wd     (fctl_glx_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fctl.glx.q ),

    // to register interface (read)
    .qs     (fctl_glx_qs)
  );


  // R[ddtp]: V(False)

  //   F[iommu_mode]: 3:0
  iommu_field #(
    .DATA_WIDTH      (4),
    .SwAccess(SwAccessRW),
    .RESVAL  (4'h0)
  ) u_ddtp_iommu_mode (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (ddtp_iommu_mode_we),
    .wd     (ddtp_iommu_mode_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.ddtp.iommu_mode.q ),

    // to register interface (read)
    .qs     (ddtp_iommu_mode_qs)
  );


  //   F[busy]: 4:4
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRO),
    .RESVAL  (1'h0)
  ) u_ddtp_busy (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware   //? don't know if it is not written by IOMMU...
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.ddtp.busy.q ),

    // to register interface (read)
    .qs     (ddtp_busy_qs)
  );


  //   F[ppn]: 53:10
  iommu_field #(
    .DATA_WIDTH      (44),
    .SwAccess(SwAccessRW),
    .RESVAL  (44'h0)
  ) u_ddtp_ppn (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (ddtp_ppn_we),
    .wd     (ddtp_ppn_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.ddtp.ppn.q ),

    // to register interface (read)
    .qs     (ddtp_ppn_qs)
  );


  // R[cqb]: V(False)

  //   F[log2sz_1]: 4:0
  iommu_field #(
    .DATA_WIDTH      (5),
    .SwAccess(SwAccessRW),
    .RESVAL  (5'h0)
  ) u_cqb_log2sz_1 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (cqb_log2sz_1_we),
    .wd     (cqb_log2sz_1_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqb.log2sz_1.q ),

    // to register interface (read)
    .qs     (cqb_log2sz_1_qs)
  );


  //   F[ppn]: 53:10
  iommu_field #(
    .DATA_WIDTH      (44),
    .SwAccess(SwAccessRW),
    .RESVAL  (44'h0)
  ) u_cqb_ppn (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (cqb_ppn_we),
    .wd     (cqb_ppn_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqb.ppn.q ),

    // to register interface (read)
    .qs     (cqb_ppn_qs)
  );


  // R[cqh]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRO),
    .RESVAL  (32'h0)
  ) u_cqh (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.cqh.de),
    .ds     (),
    .d      (hw2reg.cqh.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqh.q ),

    // to register interface (read)
    .qs     (cqh_qs)
  );


  // R[cqt]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_cqt (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (cqt_we),
    .wd     (cqt_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqt.q ),

    // to register interface (read)
    .qs     (cqt_qs)
  );


  // R[fqb]: V(False)

  //   F[log2sz_1]: 4:0
  iommu_field #(
    .DATA_WIDTH      (5),
    .SwAccess(SwAccessRW),
    .RESVAL  (5'h0)
  ) fqb_log2sz_1 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (fqb_log2sz_1_we),
    .wd     (fqb_log2sz_1_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fqb.log2sz_1.q ),

    // to register interface (read)
    .qs     (fqb_log2sz_1_qs)
  );


  //   F[ppn]: 53:10
  iommu_field #(
    .DATA_WIDTH      (44),
    .SwAccess(SwAccessRW),
    .RESVAL  (44'h0)
  ) fqb_ppn (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (fqb_ppn_we),
    .wd     (fqb_ppn_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fqb.ppn.q ),

    // to register interface (read)
    .qs     (fqb_ppn_qs)
  );


  // R[fqh]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_fqh (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (fqh_we),
    .wd     (fqh_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fqh.q ),

    // to register interface (read)
    .qs     (fqh_qs)
  );


  // R[fqt]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRO),
    .RESVAL  (32'h0)
  ) u_fqt (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.fqt.de),
    .ds     (),
    .d      (hw2reg.fqt.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fqt.q ),

    // to register interface (read)
    .qs     (fqt_qs)
  );


  // R[cqcsr]: V(False)

  //   F[cqen]: 0:0
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_cqcsr_cqen (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (cqcsr_cqen_we),
    .wd     (cqcsr_cqen_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqcsr.cqen.q ),

    // to register interface (read)
    .qs     (cqcsr_cqen_qs)
  );


  //   F[cie]: 1:1
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_cqcsr_cie (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (cqcsr_cie_we),
    .wd     (cqcsr_cie_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqcsr.cie.q ),

    // to register interface (read)
    .qs     (cqcsr_cie_qs)
  );


  //   F[cqmf]: 8:8
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessW1C),
    .RESVAL  (1'h0)
  ) u_cqcsr_cqmf (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (cqcsr_cqmf_we),
    .wd     (cqcsr_cqmf_wd),

    // from internal hardware
    .de     (hw2reg.cqcsr.cqmf.de),
    .ds     (),
    .d      (hw2reg.cqcsr.cqmf.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqcsr.cqmf.q ),

    // to register interface (read)
    .qs     (cqcsr_cqmf_qs)
  );


  //   F[cmd_to]: 9:9
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessW1C),
    .RESVAL  (1'h0)
  ) u_cqcsr_cmd_to (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (cqcsr_cmd_to_we),
    .wd     (cqcsr_cmd_to_wd),

    // from internal hardware
    .de     (hw2reg.cqcsr.cmd_to.de),
    .ds     (),
    .d      (hw2reg.cqcsr.cmd_to.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqcsr.cmd_to.q ),

    // to register interface (read)
    .qs     (cqcsr_cmd_to_qs)
  );


  //   F[cmd_ill]: 10:10
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessW1C),
    .RESVAL  (1'h0)
  ) u_cqcsr_cmd_ill (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (cqcsr_cmd_ill_we),
    .wd     (cqcsr_cmd_ill_wd),

    // from internal hardware
    .de     (hw2reg.cqcsr.cmd_ill.de),
    .ds     (),
    .d      (hw2reg.cqcsr.cmd_ill.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqcsr.cmd_ill.q ),

    // to register interface (read)
    .qs     (cqcsr_cmd_ill_qs)
  );


  //   F[fence_w_ip]: 11:11
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessW1C),
    .RESVAL  (1'h0)
  ) u_cqcsr_fence_w_ip (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (cqcsr_fence_w_ip_we),
    .wd     (cqcsr_fence_w_ip_wd),

    // from internal hardware
    .de     (hw2reg.cqcsr.fence_w_ip.de),
    .ds     (),
    .d      (hw2reg.cqcsr.fence_w_ip.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqcsr.fence_w_ip.q ),

    // to register interface (read)
    .qs     (cqcsr_fence_w_ip_qs)
  );


  //   F[cqon]: 16:16
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRO),
    .RESVAL  (1'h0)
  ) u_cqcsr_cqon (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.cqcsr.cqon.de),
    .ds     (),
    .d      (hw2reg.cqcsr.cqon.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqcsr.cqon.q ),

    // to register interface (read)
    .qs     (cqcsr_cqon_qs)
  );


  //   F[busy]: 17:17
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRO),
    .RESVAL  (1'h0)
  ) u_cqcsr_busy (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.cqcsr.busy.de),
    .ds     (),
    .d      (hw2reg.cqcsr.busy.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.cqcsr.busy.q ),

    // to register interface (read)
    .qs     (cqcsr_busy_qs)
  );


  // R[fqcsr]: V(False)

  //   F[fqen]: 0:0
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_fqcsr_fqen (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (fqcsr_fqen_we),
    .wd     (fqcsr_fqen_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fqcsr.fqen.q ),

    // to register interface (read)
    .qs     (fqcsr_fqen_qs)
  );


  //   F[fie]: 1:1
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_fqcsr_fie (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (fqcsr_fie_we),
    .wd     (fqcsr_fie_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fqcsr.fie.q ),

    // to register interface (read)
    .qs     (fqcsr_fie_qs)
  );


  //   F[fqmf]: 8:8
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessW1C),
    .RESVAL  (1'h0)
  ) u_fqcsr_fqmf (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (fqcsr_fqmf_we),
    .wd     (fqcsr_fqmf_wd),

    // from internal hardware
    .de     (hw2reg.fqcsr.fqmf.de),
    .ds     (),
    .d      (hw2reg.fqcsr.fqmf.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fqcsr.fqmf.q ),

    // to register interface (read)
    .qs     (fqcsr_fqmf_qs)
  );


  //   F[fqof]: 9:9
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessW1C),
    .RESVAL  (1'h0)
  ) u_fqcsr_fqof (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (fqcsr_fqof_we),
    .wd     (fqcsr_fqof_wd),

    // from internal hardware
    .de     (hw2reg.fqcsr.fqof.de),
    .ds     (),
    .d      (hw2reg.fqcsr.fqof.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fqcsr.fqof.q ),

    // to register interface (read)
    .qs     (fqcsr_fqof_qs)
  );


  //   F[fqon]: 16:16
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRO),
    .RESVAL  (1'h0)
  ) u_fqcsr_fqon (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.fqcsr.fqon.de),
    .ds     (),
    .d      (hw2reg.fqcsr.fqon.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fqcsr.fqon.q ),

    // to register interface (read)
    .qs     (fqcsr_fqon_qs)
  );


  //   F[busy]: 17:17
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRO),
    .RESVAL  (1'h0)
  ) u_fqcsr_busy (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    .we     (1'b0),
    .wd     ('0  ),

    // from internal hardware
    .de     (hw2reg.fqcsr.busy.de),
    .ds     (),
    .d      (hw2reg.fqcsr.busy.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fqcsr.busy.q ),

    // to register interface (read)
    .qs     (fqcsr_busy_qs)
  );


  // R[ipsr]: V(False)

  //   F[cip]: 0:0
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessW1C),
    .RESVAL  (1'h0)
  ) u_ipsr_cip (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (ipsr_cip_we),
    .wd     (ipsr_cip_wd),

    // from internal hardware
    .de     (hw2reg.ipsr.cip.de),
    .ds     (),
    .d      (hw2reg.ipsr.cip.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.ipsr.cip.q ),

    // to register interface (read)
    .qs     (ipsr_cip_qs)
  );


  //   F[fip]: 1:1
  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessW1C),
    .RESVAL  (1'h0)
  ) u_ipsr_fip (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (ipsr_fip_we),
    .wd     (ipsr_fip_wd),

    // from internal hardware
    .de     (hw2reg.ipsr.fip.de),
    .ds     (),
    .d      (hw2reg.ipsr.fip.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.ipsr.fip.q ),

    // to register interface (read)
    .qs     (ipsr_fip_qs)
  );


  //   F[pmip]: 2:2
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessW1C),
  //   .RESVAL  (1'h0)
  // ) u_ipsr_pmip (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   // from register interface
  //   .we     (ipsr_pmip_we),
  //   .wd     (ipsr_pmip_wd),

  //   // from internal hardware
  //   .de     (hw2reg.ipsr.pmip.de),
  //   .ds     (),
  //   .d      (hw2reg.ipsr.pmip.d ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.ipsr.pmip.q ),

  //   // to register interface (read)
  //   .qs     (ipsr_pmip_qs)
  // );

  assign ipsr_pmip_qs = 1'b0;


  //   F[pip]: 3:3
  // iommu_field #(
  //   .DATA_WIDTH      (1),
  //   .SwAccess(SwAccessW1C),
  //   .RESVAL  (1'h0)
  // ) u_ipsr_pip (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   // from register interface
  //   .we     (ipsr_pip_we),
  //   .wd     (ipsr_pip_wd),

  //   // from internal hardware
  //   .de     (hw2reg.ipsr.pip.de),
  //   .ds     (),
  //   .d      (hw2reg.ipsr.pip.d ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.ipsr.pip.q ),

  //   // to register interface (read)
  //   .qs     (ipsr_pip_qs)
  // );

  assign ipsr_pip_qs = 1'b0;


  // R[icvec]: V(False)

  //   F[civ]: 3:0
  iommu_field #(
    .DATA_WIDTH      (4),
    .SwAccess(SwAccessRW),
    .RESVAL  (4'h0)
  ) u_icvec_civ (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (icvec_civ_we),
    .wd     (icvec_civ_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.icvec.civ.q ),

    // to register interface (read)
    .qs     (icvec_civ_qs)
  );


  //   F[fiv]: 7:4
  iommu_field #(
    .DATA_WIDTH      (4),
    .SwAccess(SwAccessRW),
    .RESVAL  (4'h0)
  ) u_icvec_fiv (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (icvec_fiv_we),
    .wd     (icvec_fiv_wd),

    // from internal hardware
    .de     ('0),
    .d      ('0),
    .ds     (),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.icvec.fiv.q ),

    // to register interface (read)
    .qs     (icvec_fiv_qs)
  );


  //   F[pmiv]: 11:8
  // iommu_field #(
  //   .DATA_WIDTH      (4),
  //   .SwAccess(SwAccessRW),
  //   .RESVAL  (4'h0)
  // ) u_icvec_pmiv (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   // from register interface
  //   .we     (icvec_pmiv_we),
  //   .wd     (icvec_pmiv_wd),

  //   // from internal hardware
  //   .de     (hw2reg.icvec.pmiv.de),
  //   .ds     (),
  //   .d      (hw2reg.icvec.pmiv.d ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.icvec.pmiv.q ),

  //   // to register interface (read)
  //   .qs     (icvec_pmiv_qs)
  // );
  
  assign icvec_pmiv_qs = '0;


  //   F[piv]: 15:12
  // iommu_field #(
  //   .DATA_WIDTH      (4),
  //   .SwAccess(SwAccessRW),
  //   .RESVAL  (4'h0)
  // ) u_icvec_piv (
  //   .clk_i   (clk_i    ),
  //   .rst_ni  (rst_ni  ),

  //   // from register interface
  //   .we     (icvec_piv_we),
  //   .wd     (icvec_piv_wd),

  //   // from internal hardware
  //   .de     (hw2reg.icvec.piv.de),
  //   .ds     (),
  //   .d      (hw2reg.icvec.piv.d ),

  //   // to internal hardware
  //   .qe     (),
  //   .q      (reg2hw.icvec.piv.q ),

  //   // to register interface (read)
  //   .qs     (icvec_piv_qs)
  // );

  assign icvec_piv_qs = '0;


  // R[msi_addr_0]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_0_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_0_addr_we),
    .wd     (msi_addr_0_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_0.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_0.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_0.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_0_addr_qs)
  );


  // R[msi_data_0]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_0 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_0_we),
    .wd     (msi_data_0_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_0.de),
    .ds     (),
    .d      (hw2reg.msi_data_0.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_0.q ),

    // to register interface (read)
    .qs     (msi_data_0_qs)
  );


  // R[msi_vec_ctl_0]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_0 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_0_we),
    .wd     (msi_vec_ctl_0_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_0.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_0.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_0.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_0_qs)
  );


  // R[msi_addr_1]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_1_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_1_addr_we),
    .wd     (msi_addr_1_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_1.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_1.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_1.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_1_addr_qs)
  );


  // R[msi_data_1]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_1 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_1_we),
    .wd     (msi_data_1_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_1.de),
    .ds     (),
    .d      (hw2reg.msi_data_1.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_1.q ),

    // to register interface (read)
    .qs     (msi_data_1_qs)
  );


  // R[msi_vec_ctl_1]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_1 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_1_we),
    .wd     (msi_vec_ctl_1_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_1.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_1.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_1.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_1_qs)
  );


  // R[msi_addr_2]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_2_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_2_addr_we),
    .wd     (msi_addr_2_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_2.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_2.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_2.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_2_addr_qs)
  );


  // R[msi_data_2]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_2 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_2_we),
    .wd     (msi_data_2_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_2.de),
    .ds     (),
    .d      (hw2reg.msi_data_2.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_2.q ),

    // to register interface (read)
    .qs     (msi_data_2_qs)
  );


  // R[msi_vec_ctl_2]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_2 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_2_we),
    .wd     (msi_vec_ctl_2_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_2.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_2.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_2.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_2_qs)
  );


  // R[msi_addr_3]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_3_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_3_addr_we),
    .wd     (msi_addr_3_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_3.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_3.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_3.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_3_addr_qs)
  );


  // R[msi_data_3]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_3 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_3_we),
    .wd     (msi_data_3_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_3.de),
    .ds     (),
    .d      (hw2reg.msi_data_3.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_3.q ),

    // to register interface (read)
    .qs     (msi_data_3_qs)
  );


  // R[msi_vec_ctl_3]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_3 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_3_we),
    .wd     (msi_vec_ctl_3_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_3.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_3.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_3.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_3_qs)
  );


  // R[msi_addr_4]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_4_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_4_addr_we),
    .wd     (msi_addr_4_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_4.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_4.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_4.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_4_addr_qs)
  );


  // R[msi_data_4]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_4 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_4_we),
    .wd     (msi_data_4_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_4.de),
    .ds     (),
    .d      (hw2reg.msi_data_4.d ),

    // to internal hardware
    .qe     (),

    .q      (reg2hw.msi_data_4.q ),

    // to register interface (read)
    .qs     (msi_data_4_qs)
  );


  // R[msi_vec_ctl_4]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_4 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_4_we),
    .wd     (msi_vec_ctl_4_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_4.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_4.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_4.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_4_qs)
  );


  // R[msi_addr_5]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_5_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_5_addr_we),
    .wd     (msi_addr_5_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_5.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_5.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_5.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_5_addr_qs)
  );


  // R[msi_data_5]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_5 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_5_we),
    .wd     (msi_data_5_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_5.de),
    .ds     (),
    .d      (hw2reg.msi_data_5.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_5.q ),

    // to register interface (read)
    .qs     (msi_data_5_qs)
  );


  // R[msi_vec_ctl_5]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_5 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_5_we),
    .wd     (msi_vec_ctl_5_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_5.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_5.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_5.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_5_qs)
  );


  // R[msi_addr_6]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_6_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_6_addr_we),
    .wd     (msi_addr_6_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_6.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_6.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_6.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_6_addr_qs)
  );


  // R[msi_data_6]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_6 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_6_we),
    .wd     (msi_data_6_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_6.de),
    .ds     (),
    .d      (hw2reg.msi_data_6.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_6.q ),

    // to register interface (read)
    .qs     (msi_data_6_qs)
  );


  // R[msi_vec_ctl_6]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_6 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_6_we),
    .wd     (msi_vec_ctl_6_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_6.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_6.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_6.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_6_qs)
  );


  // R[msi_addr_7]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_7_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_7_addr_we),
    .wd     (msi_addr_7_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_7.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_7.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_7.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_7_addr_qs)
  );


  // R[msi_data_7]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_7 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_7_we),
    .wd     (msi_data_7_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_7.de),
    .ds     (),
    .d      (hw2reg.msi_data_7.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_7.q ),

    // to register interface (read)
    .qs     (msi_data_7_qs)
  );


  // R[msi_vec_ctl_7]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_7 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_7_we),
    .wd     (msi_vec_ctl_7_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_7.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_7.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_7.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_7_qs)
  );


  // R[msi_addr_8]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_8_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_8_addr_we),
    .wd     (msi_addr_8_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_8.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_8.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_8.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_8_addr_qs)
  );


  // R[msi_data_8]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_8 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_8_we),
    .wd     (msi_data_8_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_8.de),
    .ds     (),
    .d      (hw2reg.msi_data_8.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_8.q ),

    // to register interface (read)
    .qs     (msi_data_8_qs)
  );


  // R[msi_vec_ctl_8]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_8 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_8_we),
    .wd     (msi_vec_ctl_8_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_8.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_8.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_8.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_8_qs)
  );


  // R[msi_addr_9]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_9_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_9_addr_we),
    .wd     (msi_addr_9_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_9.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_9.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_9.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_9_addr_qs)
  );


  // R[msi_data_9]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_9 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_9_we),
    .wd     (msi_data_9_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_9.de),
    .ds     (),
    .d      (hw2reg.msi_data_9.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_9.q ),

    // to register interface (read)
    .qs     (msi_data_9_qs)
  );


  // R[msi_vec_ctl_9]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_9 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_9_we),
    .wd     (msi_vec_ctl_9_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_9.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_9.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_9.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_9_qs)
  );


  // R[msi_addr_10]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_10_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_10_addr_we),
    .wd     (msi_addr_10_addr_wd),

    // from internal hardware
    .ds     (),
    .de     (hw2reg.msi_addr_10.addr.de),
    .d      (hw2reg.msi_addr_10.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_10.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_10_addr_qs)
  );


  // R[msi_data_10]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_10 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_10_we),
    .wd     (msi_data_10_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_10.de),
    .ds     (),
    .d      (hw2reg.msi_data_10.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_10.q ),

    // to register interface (read)
    .qs     (msi_data_10_qs)
  );


  // R[msi_vec_ctl_10]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_10 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_10_we),
    .wd     (msi_vec_ctl_10_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_10.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_10.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_10.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_10_qs)
  );


  // R[msi_addr_11]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_11_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_11_addr_we),
    .wd     (msi_addr_11_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_11.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_11.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_11.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_11_addr_qs)
  );


  // R[msi_data_11]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_11 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_11_we),
    .wd     (msi_data_11_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_11.de),
    .ds     (),
    .d      (hw2reg.msi_data_11.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_11.q ),

    // to register interface (read)
    .qs     (msi_data_11_qs)
  );


  // R[msi_vec_ctl_11]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_11 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_11_we),
    .wd     (msi_vec_ctl_11_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_11.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_11.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_11.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_11_qs)
  );


  // R[msi_addr_12]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_12_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_12_addr_we),
    .wd     (msi_addr_12_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_12.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_12.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_12.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_12_addr_qs)
  );


  // R[msi_data_12]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_12 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_12_we),
    .wd     (msi_data_12_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_12.de),
    .ds     (),
    .d      (hw2reg.msi_data_12.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_12.q ),

    // to register interface (read)
    .qs     (msi_data_12_qs)
  );


  // R[msi_vec_ctl_12]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_12 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_12_we),
    .wd     (msi_vec_ctl_12_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_12.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_12.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_12.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_12_qs)
  );


  // R[msi_addr_13]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_13_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_13_addr_we),
    .wd     (msi_addr_13_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_13.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_13.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_13.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_13_addr_qs)
  );


  // R[msi_data_13]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_13 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_13_we),
    .wd     (msi_data_13_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_13.de),
    .ds     (),
    .d      (hw2reg.msi_data_13.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_13.q ),

    // to register interface (read)
    .qs     (msi_data_13_qs)
  );


  // R[msi_vec_ctl_13]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_13 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_13_we),
    .wd     (msi_vec_ctl_13_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_13.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_13.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_13.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_13_qs)
  );


  // R[msi_addr_14]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_14_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_14_addr_we),
    .wd     (msi_addr_14_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_14.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_14.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_14.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_14_addr_qs)
  );


  // R[msi_data_14]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_14 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_14_we),
    .wd     (msi_data_14_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_14.de),
    .ds     (),
    .d      (hw2reg.msi_data_14.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_14.q ),

    // to register interface (read)
    .qs     (msi_data_14_qs)
  );


  // R[msi_vec_ctl_14]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_14 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_14_we),
    .wd     (msi_vec_ctl_14_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_14.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_14.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_14.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_14_qs)
  );


  // R[msi_addr_15]: V(False)

  //   F[addr]: 55:2
  iommu_field #(
    .DATA_WIDTH      (54),
    .SwAccess(SwAccessRW),
    .RESVAL  (54'h0)
  ) u_msi_addr_15_addr (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_addr_15_addr_we),
    .wd     (msi_addr_15_addr_wd),

    // from internal hardware
    .de     (hw2reg.msi_addr_15.addr.de),
    .ds     (),
    .d      (hw2reg.msi_addr_15.addr.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_addr_15.addr.q ),

    // to register interface (read)
    .qs     (msi_addr_15_addr_qs)
  );


  // R[msi_data_15]: V(False)

  iommu_field #(
    .DATA_WIDTH      (32),
    .SwAccess(SwAccessRW),
    .RESVAL  (32'h0)
  ) u_msi_data_15 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_data_15_we),
    .wd     (msi_data_15_wd),

    // from internal hardware
    .de     (hw2reg.msi_data_15.de),
    .ds     (),
    .d      (hw2reg.msi_data_15.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_data_15.q ),

    // to register interface (read)
    .qs     (msi_data_15_qs)
  );


  // R[msi_vec_ctl_15]: V(False)

  iommu_field #(
    .DATA_WIDTH      (1),
    .SwAccess(SwAccessRW),
    .RESVAL  (1'h0)
  ) u_msi_vec_ctl_15 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (msi_vec_ctl_15_we),
    .wd     (msi_vec_ctl_15_wd),

    // from internal hardware
    .de     (hw2reg.msi_vec_ctl_15.de),
    .ds     (),
    .d      (hw2reg.msi_vec_ctl_15.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.msi_vec_ctl_15.q ),

    // to register interface (read)
    .qs     (msi_vec_ctl_15_qs)
  );

  // # Address hit logic
  // EXP: A RD/WR access is signaled by comparing the input reg_addr to the defined registers offsets
  logic [60:0] addr_hit;
  always_comb begin
    addr_hit = '0;
    addr_hit[ 0] = (reg_addr == IOMMU_CAPABILITIES_OFFSET);
    addr_hit[ 1] = (reg_addr == IOMMU_FCTL_OFFSET);
    addr_hit[ 2] = (reg_addr == IOMMU_DDTP_OFFSET);
    addr_hit[ 3] = (reg_addr == IOMMU_CQB_OFFSET);
    addr_hit[ 4] = (reg_addr == IOMMU_CQH_OFFSET);
    addr_hit[ 5] = (reg_addr == IOMMU_CQT_OFFSET);
    addr_hit[ 6] = (reg_addr == IOMMU_FQB_OFFSET);
    addr_hit[ 7] = (reg_addr == IOMMU_FQH_OFFSET);
    addr_hit[ 8] = (reg_addr == IOMMU_FQT_OFFSET);
    addr_hit[ 9] = (reg_addr == IOMMU_CQCSR_OFFSET);
    addr_hit[10] = (reg_addr == IOMMU_FQCSR_OFFSET);
    addr_hit[11] = (reg_addr == IOMMU_IPSR_OFFSET);
    addr_hit[12] = (reg_addr == IOMMU_ICVEC_OFFSET);
    addr_hit[13] = (reg_addr == IOMMU_MSI_ADDR_0_OFFSET);
    addr_hit[14] = (reg_addr == IOMMU_MSI_DATA_0_OFFSET);
    addr_hit[15] = (reg_addr == IOMMU_MSI_VEC_CTL_0_OFFSET);
    addr_hit[16] = (reg_addr == IOMMU_MSI_ADDR_1_OFFSET);
    addr_hit[17] = (reg_addr == IOMMU_MSI_DATA_1_OFFSET);
    addr_hit[18] = (reg_addr == IOMMU_MSI_VEC_CTL_1_OFFSET);
    addr_hit[19] = (reg_addr == IOMMU_MSI_ADDR_2_OFFSET);
    addr_hit[20] = (reg_addr == IOMMU_MSI_DATA_2_OFFSET);
    addr_hit[21] = (reg_addr == IOMMU_MSI_VEC_CTL_2_OFFSET);
    addr_hit[22] = (reg_addr == IOMMU_MSI_ADDR_3_OFFSET);
    addr_hit[23] = (reg_addr == IOMMU_MSI_DATA_3_OFFSET);
    addr_hit[24] = (reg_addr == IOMMU_MSI_VEC_CTL_3_OFFSET);
    addr_hit[25] = (reg_addr == IOMMU_MSI_ADDR_4_OFFSET);
    addr_hit[26] = (reg_addr == IOMMU_MSI_DATA_4_OFFSET);
    addr_hit[27] = (reg_addr == IOMMU_MSI_VEC_CTL_4_OFFSET);
    addr_hit[28] = (reg_addr == IOMMU_MSI_ADDR_5_OFFSET);
    addr_hit[29] = (reg_addr == IOMMU_MSI_DATA_5_OFFSET);
    addr_hit[30] = (reg_addr == IOMMU_MSI_VEC_CTL_5_OFFSET);
    addr_hit[31] = (reg_addr == IOMMU_MSI_ADDR_6_OFFSET);
    addr_hit[32] = (reg_addr == IOMMU_MSI_DATA_6_OFFSET);
    addr_hit[33] = (reg_addr == IOMMU_MSI_VEC_CTL_6_OFFSET);
    addr_hit[34] = (reg_addr == IOMMU_MSI_ADDR_7_OFFSET);
    addr_hit[35] = (reg_addr == IOMMU_MSI_DATA_7_OFFSET);
    addr_hit[36] = (reg_addr == IOMMU_MSI_VEC_CTL_7_OFFSET);
    addr_hit[37] = (reg_addr == IOMMU_MSI_ADDR_8_OFFSET);
    addr_hit[38] = (reg_addr == IOMMU_MSI_DATA_8_OFFSET);
    addr_hit[39] = (reg_addr == IOMMU_MSI_VEC_CTL_8_OFFSET);
    addr_hit[40] = (reg_addr == IOMMU_MSI_ADDR_9_OFFSET);
    addr_hit[41] = (reg_addr == IOMMU_MSI_DATA_9_OFFSET);
    addr_hit[42] = (reg_addr == IOMMU_MSI_VEC_CTL_9_OFFSET);
    addr_hit[43] = (reg_addr == IOMMU_MSI_ADDR_10_OFFSET);
    addr_hit[44] = (reg_addr == IOMMU_MSI_DATA_10_OFFSET);
    addr_hit[45] = (reg_addr == IOMMU_MSI_VEC_CTL_10_OFFSET);
    addr_hit[46] = (reg_addr == IOMMU_MSI_ADDR_11_OFFSET);
    addr_hit[47] = (reg_addr == IOMMU_MSI_DATA_11_OFFSET);
    addr_hit[48] = (reg_addr == IOMMU_MSI_VEC_CTL_11_OFFSET);
    addr_hit[49] = (reg_addr == IOMMU_MSI_ADDR_12_OFFSET);
    addr_hit[50] = (reg_addr == IOMMU_MSI_DATA_12_OFFSET);
    addr_hit[51] = (reg_addr == IOMMU_MSI_VEC_CTL_12_OFFSET);
    addr_hit[52] = (reg_addr == IOMMU_MSI_ADDR_13_OFFSET);
    addr_hit[53] = (reg_addr == IOMMU_MSI_DATA_13_OFFSET);
    addr_hit[54] = (reg_addr == IOMMU_MSI_VEC_CTL_13_OFFSET);
    addr_hit[55] = (reg_addr == IOMMU_MSI_ADDR_14_OFFSET);
    addr_hit[56] = (reg_addr == IOMMU_MSI_DATA_14_OFFSET);
    addr_hit[57] = (reg_addr == IOMMU_MSI_VEC_CTL_14_OFFSET);
    addr_hit[58] = (reg_addr == IOMMU_MSI_ADDR_15_OFFSET);
    addr_hit[59] = (reg_addr == IOMMU_MSI_DATA_15_OFFSET);
    addr_hit[60] = (reg_addr == IOMMU_MSI_VEC_CTL_15_OFFSET);
  end

  assign addrmiss = (reg_re || reg_we) ? ~|addr_hit : 1'b0 ;  // a miss occurs when reading or writing and no addr_hit flag is set

  // Check sub-word write is permitted
  // EXP: wr_err is set when trying to write to non-existent fields in a register
  always_comb begin
    wr_err = (reg_we &
              ((addr_hit[ 0] & (|(IOMMU_PERMIT[ 0] & ~reg_be))) |
               (addr_hit[ 1] & (|(IOMMU_PERMIT[ 1] & ~reg_be))) |
               (addr_hit[ 2] & (|(IOMMU_PERMIT[ 2] & ~reg_be))) |
               (addr_hit[ 3] & (|(IOMMU_PERMIT[ 3] & ~reg_be))) |
               (addr_hit[ 4] & (|(IOMMU_PERMIT[ 4] & ~reg_be))) |
               (addr_hit[ 5] & (|(IOMMU_PERMIT[ 5] & ~reg_be))) |
               (addr_hit[ 6] & (|(IOMMU_PERMIT[ 6] & ~reg_be))) |
               (addr_hit[ 7] & (|(IOMMU_PERMIT[ 7] & ~reg_be))) |
               (addr_hit[ 8] & (|(IOMMU_PERMIT[ 8] & ~reg_be))) |
               (addr_hit[ 9] & (|(IOMMU_PERMIT[ 9] & ~reg_be))) |
               (addr_hit[10] & (|(IOMMU_PERMIT[10] & ~reg_be))) |
               (addr_hit[11] & (|(IOMMU_PERMIT[11] & ~reg_be))) |
               (addr_hit[12] & (|(IOMMU_PERMIT[12] & ~reg_be))) |
               (addr_hit[13] & (|(IOMMU_PERMIT[13] & ~reg_be))) |
               (addr_hit[14] & (|(IOMMU_PERMIT[14] & ~reg_be))) |
               (addr_hit[15] & (|(IOMMU_PERMIT[15] & ~reg_be))) |
               (addr_hit[16] & (|(IOMMU_PERMIT[16] & ~reg_be))) |
               (addr_hit[17] & (|(IOMMU_PERMIT[17] & ~reg_be))) |
               (addr_hit[18] & (|(IOMMU_PERMIT[18] & ~reg_be))) |
               (addr_hit[19] & (|(IOMMU_PERMIT[19] & ~reg_be))) |
               (addr_hit[20] & (|(IOMMU_PERMIT[20] & ~reg_be))) |
               (addr_hit[21] & (|(IOMMU_PERMIT[21] & ~reg_be))) |
               (addr_hit[22] & (|(IOMMU_PERMIT[22] & ~reg_be))) |
               (addr_hit[23] & (|(IOMMU_PERMIT[23] & ~reg_be))) |
               (addr_hit[24] & (|(IOMMU_PERMIT[24] & ~reg_be))) |
               (addr_hit[25] & (|(IOMMU_PERMIT[25] & ~reg_be))) |
               (addr_hit[26] & (|(IOMMU_PERMIT[26] & ~reg_be))) |
               (addr_hit[27] & (|(IOMMU_PERMIT[27] & ~reg_be))) |
               (addr_hit[28] & (|(IOMMU_PERMIT[28] & ~reg_be))) |
               (addr_hit[29] & (|(IOMMU_PERMIT[29] & ~reg_be))) |
               (addr_hit[30] & (|(IOMMU_PERMIT[30] & ~reg_be))) |
               (addr_hit[31] & (|(IOMMU_PERMIT[31] & ~reg_be))) |
               (addr_hit[32] & (|(IOMMU_PERMIT[32] & ~reg_be))) |
               (addr_hit[33] & (|(IOMMU_PERMIT[33] & ~reg_be))) |
               (addr_hit[34] & (|(IOMMU_PERMIT[34] & ~reg_be))) |
               (addr_hit[35] & (|(IOMMU_PERMIT[35] & ~reg_be))) |
               (addr_hit[36] & (|(IOMMU_PERMIT[36] & ~reg_be))) |
               (addr_hit[37] & (|(IOMMU_PERMIT[37] & ~reg_be))) |
               (addr_hit[38] & (|(IOMMU_PERMIT[38] & ~reg_be))) |
               (addr_hit[39] & (|(IOMMU_PERMIT[39] & ~reg_be))) |
               (addr_hit[40] & (|(IOMMU_PERMIT[40] & ~reg_be))) |
               (addr_hit[41] & (|(IOMMU_PERMIT[41] & ~reg_be))) |
               (addr_hit[42] & (|(IOMMU_PERMIT[42] & ~reg_be))) |
               (addr_hit[43] & (|(IOMMU_PERMIT[43] & ~reg_be))) |
               (addr_hit[44] & (|(IOMMU_PERMIT[44] & ~reg_be))) |
               (addr_hit[45] & (|(IOMMU_PERMIT[45] & ~reg_be))) |
               (addr_hit[46] & (|(IOMMU_PERMIT[46] & ~reg_be))) |
               (addr_hit[47] & (|(IOMMU_PERMIT[47] & ~reg_be))) |
               (addr_hit[48] & (|(IOMMU_PERMIT[48] & ~reg_be))) |
               (addr_hit[49] & (|(IOMMU_PERMIT[49] & ~reg_be))) |
               (addr_hit[50] & (|(IOMMU_PERMIT[50] & ~reg_be))) |
               (addr_hit[51] & (|(IOMMU_PERMIT[51] & ~reg_be))) |
               (addr_hit[52] & (|(IOMMU_PERMIT[52] & ~reg_be))) |
               (addr_hit[53] & (|(IOMMU_PERMIT[53] & ~reg_be))) |
               (addr_hit[54] & (|(IOMMU_PERMIT[54] & ~reg_be))) |
               (addr_hit[55] & (|(IOMMU_PERMIT[55] & ~reg_be))) |
               (addr_hit[56] & (|(IOMMU_PERMIT[56] & ~reg_be))) |
               (addr_hit[57] & (|(IOMMU_PERMIT[57] & ~reg_be))) |
               (addr_hit[58] & (|(IOMMU_PERMIT[58] & ~reg_be))) |
               (addr_hit[59] & (|(IOMMU_PERMIT[59] & ~reg_be))) |
               (addr_hit[60] & (|(IOMMU_PERMIT[60] & ~reg_be)))));
  end

  //# Write data logic
  //
  // EXP: The WE signal for each FIELD is set if global WE is set, and the corresponding REG addr_hit flag is set, and there is no error
  //      The WD for each FIELD is connected to the correspondind bits of the reg_wdata input signal
  // NOTE:  Writes are performed by REG, not by FIELD. It is up to the software to maintain the same values in the other fields when it is desired
  //        to write to a particular field

	// Hardwire fctl.BE since we are only using little-endian processing
	// assign fctl_be_we = addr_hit[1] & reg_we & !reg_error;
	// assign fctl_be_wd = reg_wdata[0];

  // Interrupts can not be generated as MSI (0) if caps.IGS != {0,2}, and can not be generated as WSI (1) if caps.IGS != {1,2}
  // always_comb begin
  //   if((addr_hit[1] & reg_we & !reg_error) & 
  //       (reg_wdata[1] == 1'b0 & reg2hw.capabilities.igs.q inside {2'b00, 2'b10}) | 
  //       (reg_wdata[1] == 1'b1 & reg2hw.capabilities.igs.q inside {2'b01, 2'b10}))
  //     fctl_wsi_we = 1'b1;
  // end
  assign fctl_wsi_we = (addr_hit[1] & reg_we & !reg_error) & 
    (reg_wdata[1] == 1'b0 & reg2hw.capabilities.igs.q inside {2'b00, 2'b10}) | 
    (reg_wdata[1] == 1'b1 & reg2hw.capabilities.igs.q inside {2'b01, 2'b10});
  assign fctl_wsi_wd = reg_wdata[1];

  assign fctl_glx_we = addr_hit[1] & reg_we & !reg_error;
  assign fctl_glx_wd = reg_wdata[2];

  // Only values less or equal than 4 can be written to ddtp.iommu_mode
  assign ddtp_iommu_mode_we = addr_hit[2] & reg_we & !reg_error & (reg_wdata[3:0] <= 4);
  assign ddtp_iommu_mode_wd = reg_wdata[3:0];

  assign ddtp_ppn_we = addr_hit[2] & reg_we & !reg_error;
  assign ddtp_ppn_wd = reg_wdata[53:10];

  assign cqb_log2sz_1_we = addr_hit[3] & reg_we & !reg_error;
  assign cqb_log2sz_1_wd = reg_wdata[4:0];

  assign cqb_ppn_we = addr_hit[3] & reg_we & !reg_error;
  assign cqb_ppn_wd = reg_wdata[53:10];

  // Only LOG2SZ-1:0 bits are writable.
  assign cqt_we = addr_hit[5] & reg_we & !reg_error;
  assign cqt_wd = reg_wdata[31:0] & ({32{1'b1}} >> (31 - reg2hw.cqb.log2sz_1.q));

  assign fqb_log2sz_1_we = addr_hit[6] & reg_we & !reg_error;
  assign fqb_log2sz_1_wd = reg_wdata[4:0];

  assign fqb_ppn_we = addr_hit[6] & reg_we & !reg_error;
  assign fqb_ppn_wd = reg_wdata[53:10];

  // Only LOG2SZ-1:0 bits are writable.
  assign fqh_we = addr_hit[7] & reg_we & !reg_error;
  assign fqh_wd = reg_wdata[31:0] & ({32{1'b1}} >> (31 - reg2hw.fqb.log2sz_1.q));

  assign cqcsr_cqen_we = addr_hit[9] & reg_we & !reg_error;
  assign cqcsr_cqen_wd = reg_wdata[0];

  assign cqcsr_cie_we = addr_hit[9] & reg_we & !reg_error;
  assign cqcsr_cie_wd = reg_wdata[1];

  assign cqcsr_cqmf_we = addr_hit[9] & reg_we & !reg_error;
  assign cqcsr_cqmf_wd = reg_wdata[8];

  assign cqcsr_cmd_to_we = addr_hit[9] & reg_we & !reg_error;
  assign cqcsr_cmd_to_wd = reg_wdata[9];

  assign cqcsr_cmd_ill_we = addr_hit[9] & reg_we & !reg_error;
  assign cqcsr_cmd_ill_wd = reg_wdata[10];

  assign cqcsr_fence_w_ip_we = addr_hit[9] & reg_we & !reg_error;
  assign cqcsr_fence_w_ip_wd = reg_wdata[11];

  assign fqcsr_fqen_we = addr_hit[10] & reg_we & !reg_error;
  assign fqcsr_fqen_wd = reg_wdata[0];

  assign fqcsr_fie_we = addr_hit[10] & reg_we & !reg_error;
  assign fqcsr_fie_wd = reg_wdata[1];

  assign fqcsr_fqmf_we = addr_hit[10] & reg_we & !reg_error;
  assign fqcsr_fqmf_wd = reg_wdata[8];

  assign fqcsr_fqof_we = addr_hit[10] & reg_we & !reg_error;
  assign fqcsr_fqof_wd = reg_wdata[9];

  assign ipsr_cip_we = addr_hit[11] & reg_we & !reg_error;
  assign ipsr_cip_wd = reg_wdata[0];

  assign ipsr_fip_we = addr_hit[11] & reg_we & !reg_error;
  assign ipsr_fip_wd = reg_wdata[1];

  assign ipsr_pmip_we = addr_hit[11] & reg_we & !reg_error;
  assign ipsr_pmip_wd = reg_wdata[2];

  assign ipsr_pip_we = addr_hit[11] & reg_we & !reg_error;
  assign ipsr_pip_wd = reg_wdata[3];

  assign icvec_civ_we = addr_hit[12] & reg_we & !reg_error;
  assign icvec_civ_wd = reg_wdata[3:0];

  assign icvec_fiv_we = addr_hit[12] & reg_we & !reg_error;
  assign icvec_fiv_wd = reg_wdata[7:4];

  assign icvec_pmiv_we = addr_hit[12] & reg_we & !reg_error;
  assign icvec_pmiv_wd = reg_wdata[11:8];

  assign icvec_piv_we = addr_hit[12] & reg_we & !reg_error;
  assign icvec_piv_wd = reg_wdata[15:12];

  assign msi_addr_0_addr_we = addr_hit[13] & reg_we & !reg_error;
  assign msi_addr_0_addr_wd = reg_wdata[55:2];

  assign msi_data_0_we = addr_hit[14] & reg_we & !reg_error;
  assign msi_data_0_wd = reg_wdata[31:0];

  assign msi_vec_ctl_0_we = addr_hit[15] & reg_we & !reg_error;
  assign msi_vec_ctl_0_wd = reg_wdata[0];

  assign msi_addr_1_addr_we = addr_hit[16] & reg_we & !reg_error;
  assign msi_addr_1_addr_wd = reg_wdata[55:2];

  assign msi_data_1_we = addr_hit[17] & reg_we & !reg_error;
  assign msi_data_1_wd = reg_wdata[31:0];

  assign msi_vec_ctl_1_we = addr_hit[18] & reg_we & !reg_error;
  assign msi_vec_ctl_1_wd = reg_wdata[0];

  assign msi_addr_2_addr_we = addr_hit[19] & reg_we & !reg_error;
  assign msi_addr_2_addr_wd = reg_wdata[55:2];

  assign msi_data_2_we = addr_hit[20] & reg_we & !reg_error;
  assign msi_data_2_wd = reg_wdata[31:0];

  assign msi_vec_ctl_2_we = addr_hit[21] & reg_we & !reg_error;
  assign msi_vec_ctl_2_wd = reg_wdata[0];

  assign msi_addr_3_addr_we = addr_hit[22] & reg_we & !reg_error;
  assign msi_addr_3_addr_wd = reg_wdata[55:2];

  assign msi_data_3_we = addr_hit[23] & reg_we & !reg_error;
  assign msi_data_3_wd = reg_wdata[31:0];

  assign msi_vec_ctl_3_we = addr_hit[24] & reg_we & !reg_error;
  assign msi_vec_ctl_3_wd = reg_wdata[0];

  assign msi_addr_4_addr_we = addr_hit[25] & reg_we & !reg_error;
  assign msi_addr_4_addr_wd = reg_wdata[55:2];

  assign msi_data_4_we = addr_hit[26] & reg_we & !reg_error;
  assign msi_data_4_wd = reg_wdata[31:0];

  assign msi_vec_ctl_4_we = addr_hit[27] & reg_we & !reg_error;
  assign msi_vec_ctl_4_wd = reg_wdata[0];

  assign msi_addr_5_addr_we = addr_hit[28] & reg_we & !reg_error;
  assign msi_addr_5_addr_wd = reg_wdata[55:2];

  assign msi_data_5_we = addr_hit[29] & reg_we & !reg_error;
  assign msi_data_5_wd = reg_wdata[31:0];

  assign msi_vec_ctl_5_we = addr_hit[30] & reg_we & !reg_error;
  assign msi_vec_ctl_5_wd = reg_wdata[0];

  assign msi_addr_6_addr_we = addr_hit[31] & reg_we & !reg_error;
  assign msi_addr_6_addr_wd = reg_wdata[55:2];

  assign msi_data_6_we = addr_hit[32] & reg_we & !reg_error;
  assign msi_data_6_wd = reg_wdata[31:0];

  assign msi_vec_ctl_6_we = addr_hit[33] & reg_we & !reg_error;
  assign msi_vec_ctl_6_wd = reg_wdata[0];

  assign msi_addr_7_addr_we = addr_hit[34] & reg_we & !reg_error;
  assign msi_addr_7_addr_wd = reg_wdata[55:2];

  assign msi_data_7_we = addr_hit[35] & reg_we & !reg_error;
  assign msi_data_7_wd = reg_wdata[31:0];

  assign msi_vec_ctl_7_we = addr_hit[36] & reg_we & !reg_error;
  assign msi_vec_ctl_7_wd = reg_wdata[0];

  assign msi_addr_8_addr_we = addr_hit[37] & reg_we & !reg_error;
  assign msi_addr_8_addr_wd = reg_wdata[55:2];

  assign msi_data_8_we = addr_hit[38] & reg_we & !reg_error;
  assign msi_data_8_wd = reg_wdata[31:0];

  assign msi_vec_ctl_8_we = addr_hit[39] & reg_we & !reg_error;
  assign msi_vec_ctl_8_wd = reg_wdata[0];

  assign msi_addr_9_addr_we = addr_hit[40] & reg_we & !reg_error;
  assign msi_addr_9_addr_wd = reg_wdata[55:2];

  assign msi_data_9_we = addr_hit[41] & reg_we & !reg_error;
  assign msi_data_9_wd = reg_wdata[31:0];

  assign msi_vec_ctl_9_we = addr_hit[42] & reg_we & !reg_error;
  assign msi_vec_ctl_9_wd = reg_wdata[0];

  assign msi_addr_10_addr_we = addr_hit[43] & reg_we & !reg_error;
  assign msi_addr_10_addr_wd = reg_wdata[55:2];

  assign msi_data_10_we = addr_hit[44] & reg_we & !reg_error;
  assign msi_data_10_wd = reg_wdata[31:0];

  assign msi_vec_ctl_10_we = addr_hit[45] & reg_we & !reg_error;
  assign msi_vec_ctl_10_wd = reg_wdata[0];

  assign msi_addr_11_addr_we = addr_hit[46] & reg_we & !reg_error;
  assign msi_addr_11_addr_wd = reg_wdata[55:2];

  assign msi_data_11_we = addr_hit[47] & reg_we & !reg_error;
  assign msi_data_11_wd = reg_wdata[31:0];

  assign msi_vec_ctl_11_we = addr_hit[48] & reg_we & !reg_error;
  assign msi_vec_ctl_11_wd = reg_wdata[0];

  assign msi_addr_12_addr_we = addr_hit[49] & reg_we & !reg_error;
  assign msi_addr_12_addr_wd = reg_wdata[55:2];

  assign msi_data_12_we = addr_hit[50] & reg_we & !reg_error;
  assign msi_data_12_wd = reg_wdata[31:0];

  assign msi_vec_ctl_12_we = addr_hit[51] & reg_we & !reg_error;
  assign msi_vec_ctl_12_wd = reg_wdata[0];

  assign msi_addr_13_addr_we = addr_hit[52] & reg_we & !reg_error;
  assign msi_addr_13_addr_wd = reg_wdata[55:2];

  assign msi_data_13_we = addr_hit[53] & reg_we & !reg_error;
  assign msi_data_13_wd = reg_wdata[31:0];

  assign msi_vec_ctl_13_we = addr_hit[54] & reg_we & !reg_error;
  assign msi_vec_ctl_13_wd = reg_wdata[0];

  assign msi_addr_14_addr_we = addr_hit[55] & reg_we & !reg_error;
  assign msi_addr_14_addr_wd = reg_wdata[55:2];

  assign msi_data_14_we = addr_hit[56] & reg_we & !reg_error;
  assign msi_data_14_wd = reg_wdata[31:0];

  assign msi_vec_ctl_14_we = addr_hit[57] & reg_we & !reg_error;
  assign msi_vec_ctl_14_wd = reg_wdata[0];

  assign msi_addr_15_addr_we = addr_hit[58] & reg_we & !reg_error;
  assign msi_addr_15_addr_wd = reg_wdata[55:2];

  assign msi_data_15_we = addr_hit[59] & reg_we & !reg_error;
  assign msi_data_15_wd = reg_wdata[31:0];

  assign msi_vec_ctl_15_we = addr_hit[60] & reg_we & !reg_error;
  assign msi_vec_ctl_15_wd = reg_wdata[0];

  // # Read data logic
  // EXP: addr_hit contains one bit per register that is set when the corresponging register address matches the one in the input bus
  //      This means that a read/write is being performed, so the current register data is placed in the reg interface read bus
  always_comb begin
    reg_rdata_next = '0;
    unique case (1'b1)
      addr_hit[0]: begin
        reg_rdata_next[7:0] = capabilities_version_qs;
        reg_rdata_next[8] = capabilities_sv32_qs;
        reg_rdata_next[9] = capabilities_sv39_qs;
        reg_rdata_next[10] = capabilities_sv48_qs;
        reg_rdata_next[11] = capabilities_sv57_qs;
        reg_rdata_next[14:12] = '0;
        reg_rdata_next[15] = capabilities_svpbmt_qs;
        reg_rdata_next[16] = capabilities_sv32x4_qs;
        reg_rdata_next[17] = capabilities_sv39x4_qs;
        reg_rdata_next[18] = capabilities_sv48x4_qs;
        reg_rdata_next[19] = capabilities_sv57x4_qs;
        reg_rdata_next[21:20] = '0;
        reg_rdata_next[22] = capabilities_msi_flat_qs;
        reg_rdata_next[23] = capabilities_msi_mrif_qs;
        reg_rdata_next[24] = capabilities_amo_qs;
        reg_rdata_next[25] = capabilities_ats_qs;
        reg_rdata_next[26] = capabilities_t2gpa_qs;
        reg_rdata_next[27] = capabilities_endi_qs;
        reg_rdata_next[29:28] = capabilities_igs_qs;
        reg_rdata_next[30] = capabilities_hpm_qs;
        reg_rdata_next[31] = capabilities_dbg_qs;
        reg_rdata_next[37:32] = capabilities_pas_qs;
        reg_rdata_next[38] = capabilities_pd8_qs;
        reg_rdata_next[39] = capabilities_pd17_qs;
        reg_rdata_next[40] = capabilities_pd20_qs;
        reg_rdata_next[55:41] = '0;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[1]: begin
        reg_rdata_next[0] = fctl_be_qs;
        reg_rdata_next[1] = fctl_wsi_qs;
        reg_rdata_next[2] = fctl_glx_qs;
        reg_rdata_next[15:3] = '0;
        reg_rdata_next[31:16] = '0;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[2]: begin
        reg_rdata_next[3:0] = ddtp_iommu_mode_qs;
        reg_rdata_next[4] = ddtp_busy_qs;
        reg_rdata_next[9:5] = '0;
        reg_rdata_next[53:10] = ddtp_ppn_qs;
        reg_rdata_next[63:54] = '0;
      end

      addr_hit[3]: begin
        reg_rdata_next[4:0] = cqb_log2sz_1_qs;
        reg_rdata_next[9:5] = '0;
        reg_rdata_next[53:10] = cqb_ppn_qs;
        reg_rdata_next[63:54] = '0;
      end

      addr_hit[4]: begin
        reg_rdata_next[31:0] = cqh_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[5]: begin
        reg_rdata_next[31:0] = cqt_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[6]: begin
        reg_rdata_next[4:0] = fqb_log2sz_1_qs;
        reg_rdata_next[9:5] = '0;
        reg_rdata_next[53:10] = fqb_ppn_qs;
        reg_rdata_next[63:54] = '0;
      end

      addr_hit[7]: begin
        reg_rdata_next[31:0] = fqh_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[8]: begin
        reg_rdata_next[31:0] = fqt_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[9]: begin
        reg_rdata_next[0] = cqcsr_cqen_qs;
        reg_rdata_next[1] = cqcsr_cie_qs;
        reg_rdata_next[7:2] = '0;
        reg_rdata_next[8] = cqcsr_cqmf_qs;
        reg_rdata_next[9] = cqcsr_cmd_to_qs;
        reg_rdata_next[10] = cqcsr_cmd_ill_qs;
        reg_rdata_next[11] = cqcsr_fence_w_ip_qs;
        reg_rdata_next[15:12] = '0;
        reg_rdata_next[16] = cqcsr_cqon_qs;
        reg_rdata_next[17] = cqcsr_busy_qs;
        reg_rdata_next[27:18] = '0;
        reg_rdata_next[31:28] = '0;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[10]: begin
        reg_rdata_next[0] = fqcsr_fqen_qs;
        reg_rdata_next[1] = fqcsr_fie_qs;
        reg_rdata_next[7:2] = '0;
        reg_rdata_next[8] = fqcsr_fqmf_qs;
        reg_rdata_next[9] = fqcsr_fqof_qs;
        reg_rdata_next[15:10] = '0;
        reg_rdata_next[16] = fqcsr_fqon_qs;
        reg_rdata_next[17] = fqcsr_busy_qs;
        reg_rdata_next[27:18] = '0;
        reg_rdata_next[31:28] = '0;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[11]: begin
        reg_rdata_next[0] = ipsr_cip_qs;
        reg_rdata_next[1] = ipsr_fip_qs;
        reg_rdata_next[2] = ipsr_pmip_qs;
        reg_rdata_next[3] = ipsr_pip_qs;
        reg_rdata_next[63:4] = '0;
      end

      addr_hit[12]: begin
        reg_rdata_next[3:0] = icvec_civ_qs;
        reg_rdata_next[7:4] = icvec_fiv_qs;
        reg_rdata_next[11:8] = icvec_pmiv_qs;
        reg_rdata_next[15:12] = icvec_piv_qs;
        reg_rdata_next[63:16] = '0;
      end

      addr_hit[13]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_0_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[14]: begin
        reg_rdata_next[31:0] = msi_data_0_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[15]: begin
        reg_rdata_next[0] = msi_vec_ctl_0_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[16]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_1_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[17]: begin
        reg_rdata_next[31:0] = msi_data_1_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[18]: begin
        reg_rdata_next[0] = msi_vec_ctl_1_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[19]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_2_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[20]: begin
        reg_rdata_next[31:0] = msi_data_2_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[21]: begin
        reg_rdata_next[0] = msi_vec_ctl_2_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[22]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_3_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[23]: begin
        reg_rdata_next[31:0] = msi_data_3_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[24]: begin
        reg_rdata_next[0] = msi_vec_ctl_3_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[25]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_4_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[26]: begin
        reg_rdata_next[31:0] = msi_data_4_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[27]: begin
        reg_rdata_next[0] = msi_vec_ctl_4_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[28]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_5_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[29]: begin
        reg_rdata_next[31:0] = msi_data_5_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[30]: begin
        reg_rdata_next[0] = msi_vec_ctl_5_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[31]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_6_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[32]: begin
        reg_rdata_next[31:0] = msi_data_6_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[33]: begin
        reg_rdata_next[0] = msi_vec_ctl_6_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[34]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_7_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[35]: begin
        reg_rdata_next[31:0] = msi_data_7_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[36]: begin
        reg_rdata_next[0] = msi_vec_ctl_7_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[37]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_8_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[38]: begin
        reg_rdata_next[31:0] = msi_data_8_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[39]: begin
        reg_rdata_next[0] = msi_vec_ctl_8_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[40]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_9_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[41]: begin
        reg_rdata_next[31:0] = msi_data_9_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[42]: begin
        reg_rdata_next[0] = msi_vec_ctl_9_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[43]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_10_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[44]: begin
        reg_rdata_next[31:0] = msi_data_10_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[45]: begin
        reg_rdata_next[0] = msi_vec_ctl_10_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[46]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_11_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[47]: begin
        reg_rdata_next[31:0] = msi_data_11_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[48]: begin
        reg_rdata_next[0] = msi_vec_ctl_11_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[49]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_12_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[50]: begin
        reg_rdata_next[31:0] = msi_data_12_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[51]: begin
        reg_rdata_next[0] = msi_vec_ctl_12_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[52]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_13_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[53]: begin
        reg_rdata_next[31:0] = msi_data_13_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[54]: begin
        reg_rdata_next[0] = msi_vec_ctl_13_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[55]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_14_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[56]: begin
        reg_rdata_next[31:0] = msi_data_14_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[57]: begin
        reg_rdata_next[0] = msi_vec_ctl_14_qs;
        reg_rdata_next[63:1] = '0;
      end

      addr_hit[58]: begin
        reg_rdata_next[1:0] = '0;
        reg_rdata_next[55:2] = msi_addr_15_addr_qs;
        reg_rdata_next[63:56] = '0;
      end

      addr_hit[59]: begin
        reg_rdata_next[31:0] = msi_data_15_qs;
        reg_rdata_next[63:32] = '0;
      end

      addr_hit[60]: begin
        reg_rdata_next[0] = msi_vec_ctl_15_qs;
        reg_rdata_next[63:1] = '0;
      end

      default: begin
        reg_rdata_next = '1;
      end
    endcase
  end

  // * Unused signal tieoff

  // wdata / byte enable are not always fully used
  // add a blanket unused statement to handle lint waivers
  logic unused_wdata;
  logic unused_be;
  assign unused_wdata = ^reg_wdata;
  assign unused_be = ^reg_be;

  // Assertions for Register Interface
  `ASSERT(en2addrHit, (reg_we || reg_re) |-> $onehot0(addr_hit))

endmodule