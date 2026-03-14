/**
 * UIM OAuth 2.0 Service (OAU)
 *
 * Authorization and authentication based on the OAuth 2.0 protocol.
 * Supports authorization code grant (web apps), client credentials
 * grant (API/IoT), token introspection, and token revocation.
 */
module uim.sap.oau;

public import uim.sap.oau.config;
public import uim.sap.oau.enumerations;
public import uim.sap.oau.exceptions;
public import uim.sap.oau.helpers;
public import uim.sap.oau.models;
public import uim.sap.oau.store;
public import uim.sap.oau.service;
public import uim.sap.oau.server;

enum UIM_OAU_VERSION = "1.0.0";
