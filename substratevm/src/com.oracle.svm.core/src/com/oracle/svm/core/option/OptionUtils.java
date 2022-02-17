/*
 * Copyright (c) 2018, 2018, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */
package com.oracle.svm.core.option;

import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.graalvm.compiler.options.OptionKey;

import com.oracle.svm.core.SubstrateUtil;
import com.oracle.svm.core.util.UserError;

/**
 * This class contains static helper methods related to options.
 */
public class OptionUtils {

    /**
     * Utility for string option values that are a, e.g., comma-separated list, but can also be
     * provided multiple times on the command line (so the option type is
     * LocatableMultiOptionValue.Strings). The returned list contains all {@link String#trim()
     * trimmed} string parts, with empty strings filtered out.
     */
    public static List<String> flatten(String delimiter, LocatableMultiOptionValue.Strings values) {
        return flatten(delimiter, values.values());
    }

    public static List<String> flatten(String delimiter, String[] values) {
        if (values == null) {
            return Collections.emptyList();
        }
        return flatten(delimiter, Arrays.asList(values));
    }

    public static List<String> flatten(String delimiter, List<String> values) {
        List<String> result = new ArrayList<>();
        for (String value : values) {
            if (value != null && !value.isEmpty()) {
                for (String component : SubstrateUtil.split(value, delimiter)) {
                    String trimmed = component.trim();
                    if (!trimmed.isEmpty()) {
                        result.add(trimmed);
                    }
                }
            }
        }
        return result;
    }

    public static List<String> resolveOptionValueRedirection(OptionKey<?> option, String optionValue, OptionOrigin origin) {
        return Arrays.asList(SubstrateUtil.split(optionValue, ",")).stream()
                        .flatMap(entry -> resolveOptionValueRedirectionFlatMap(option, optionValue, origin, entry))
                        .collect(Collectors.toList());
    }

    private static Stream<? extends String> resolveOptionValueRedirectionFlatMap(OptionKey<?> option, String optionValue, OptionOrigin origin, String entry) {
        if (entry.trim().startsWith("@")) {
            Path valuesFile = Path.of(entry.substring(1));
            if (valuesFile.isAbsolute()) {
                throw UserError.abort("Option '%s' provided by %s contains value redirection file '%s' that is an absolute path.",
                                SubstrateOptionsParser.commandArgument(option, optionValue), origin, valuesFile);
            }
            try {
                return origin.getRedirectionValues(valuesFile).stream();
            } catch (IOException e) {
                throw UserError.abort(e, "Option '%s' provided by %s contains invalid option value redirection.",
                                SubstrateOptionsParser.commandArgument(option, optionValue), origin);
            }
        } else {
            return Stream.of(entry);
        }
    }

    public enum MacroOptionKind {

        Language("languages", true),
        Tool("tools", true),
        Macro("macros", false);

        public static final String macroOptionPrefix = "--";

        public final String subdir;
        public final boolean allowAll;

        MacroOptionKind(String subdir, boolean allowAll) {
            this.subdir = subdir;
            this.allowAll = allowAll;
        }

        public static MacroOptionKind fromSubdir(String subdir) {
            for (MacroOptionKind kind : MacroOptionKind.values()) {
                if (kind.subdir.equals(subdir)) {
                    return kind;
                }
            }
            throw new InvalidMacroException("No MacroOptionKind for subDir: " + subdir);
        }

        public static MacroOptionKind fromString(String kindName) {
            for (MacroOptionKind kind : MacroOptionKind.values()) {
                if (kind.toString().equals(kindName)) {
                    return kind;
                }
            }
            throw new InvalidMacroException("No MacroOptionKind for kindName: " + kindName);
        }

        public String getDescriptionPrefix(boolean commandLineStyle) {
            StringBuilder sb = new StringBuilder();
            if (commandLineStyle) {
                sb.append(macroOptionPrefix);
            }
            sb.append(this).append(":");
            return sb.toString();
        }

        @Override
        public String toString() {
            return name().toLowerCase();
        }
    }

    @SuppressWarnings("serial")
    public static final class InvalidMacroException extends RuntimeException {
        public InvalidMacroException(String arg0) {
            super(arg0);
        }
    }
}
