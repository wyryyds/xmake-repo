package("aws-crt-cpp")
    set_homepage("https://github.com/awslabs/aws-crt-cpp")
    set_description("C++ wrapper around the aws-c-* libraries. Provides Cross-Platform Transport Protocols and SSL/TLS implementations for C++.")
    set_license("Apache-2.0")

    add_urls("https://github.com/awslabs/aws-crt-cpp/archive/refs/tags/$(version).tar.gz",
             "https://github.com/awslabs/aws-crt-cpp.git")

    add_versions("v0.26.9", "5b5760d34fbbfcc971f561296e828de4c788750472fd9bd3ac20068a083620f2")
    add_versions("v0.26.8", "36ced4fb54c8eb7325b4576134e01f93bfaca2709565b5ad036d198d703e4c8f")
    add_versions("v0.26.4", "486113a556614b7b824e1aefec365a2261154fe06321b85601aefe2f65bd0706")
    add_versions("v0.23.1", "8f7029fea12907564b80260cbea4a2b268ca678e7427def3e0c46871e9b42d16")

    add_configs("openssl", {description = "Set this if you want to use your system's OpenSSL 1.0.2/1.1.1 compatible libcrypto", default = false, type = "boolean"})

    add_deps("cmake", "aws-c-common", "aws-c-io", "aws-checksums", "aws-c-event-stream",
             "aws-c-http", "aws-c-mqtt", "aws-c-auth", "aws-c-s3")

    on_install("windows|x64", "windows|x86", "linux", "macosx", "bsd", "msys", function (package)
        local cmakedir = package:dep("aws-c-common"):installdir("lib", "cmake")
        if package:is_plat("windows") then
            cmakedir = cmakedir:gsub("\\", "/")
        end

        local configs = {"-DBUILD_TESTING=OFF", "-DCMAKE_MODULE_PATH=" .. cmakedir, "-DBUILD_DEPS=OFF"}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        table.insert(configs, "-DENABLE_SANITIZERS=" .. (package:config("asan") and "ON" or "OFF"))
        if package:is_plat("windows") then
            table.insert(configs, "-DAWS_STATIC_MSVC_RUNTIME_LIBRARY=" .. (package:config("vs_runtime"):startswith("MT") and "ON" or "OFF"))

            io.replace("include/aws/crt/Exports.h", "WIN32", "_WIN32", {plain = true})
            if package:config("shared") then
                package:add("defines", "AWS_CRT_CPP_USE_IMPORT_EXPORT")
            end
        end
        table.insert(configs, "-DUSE_OPENSSL=" .. (package:config("openssl") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <aws/crt/Api.h>
            void test() {
                Aws::Crt::ApiHandle apiHandle;
            }
        ]]}, {configs = {languages = "c++11"}}))
    end)
