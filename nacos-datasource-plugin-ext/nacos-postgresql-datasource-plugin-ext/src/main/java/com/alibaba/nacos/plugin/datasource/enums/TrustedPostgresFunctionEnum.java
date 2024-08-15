package com.alibaba.nacos.plugin.datasource.enums;

import java.util.HashMap;
import java.util.Map;

/**
 * @author fuhouyu
 */
public enum TrustedPostgresFunctionEnum {

    /**
     * NOW().
     */
    NOW("NOW()", "CURRENT_TIMESTAMP");

    private static final Map<String, TrustedPostgresFunctionEnum> LOOKUP_MAP = new HashMap<>();

    static {
        for (TrustedPostgresFunctionEnum entry : TrustedPostgresFunctionEnum.values()) {
            LOOKUP_MAP.put(entry.functionName, entry);
        }
    }

    private final String functionName;

    private final String function;

    TrustedPostgresFunctionEnum(String functionName, String function) {
        this.functionName = functionName;
        this.function = function;
    }

    /**
     * Get the function name.
     *
     * @param functionName function name
     * @return function
     */
    public static String getFunctionByName(String functionName) {
        TrustedPostgresFunctionEnum entry = LOOKUP_MAP.get(functionName);
        if (entry != null) {
            return entry.function;
        }
        throw new IllegalArgumentException(String.format("Invalid function name: %s", functionName));
    }
}
