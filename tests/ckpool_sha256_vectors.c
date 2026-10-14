/* Test the same SHA256 implementation used for pool work and block headers. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sha2.h"

#if defined(USE_AVX2) || defined(USE_AVX1) || defined(USE_SSE4)
#error Portability vectors must exercise the portable C implementation
#endif

static int check_digest(const char *name, const unsigned char digest[32],
                        const char *expected)
{
    char hexadecimal[65];
    for (unsigned int i = 0; i < 32; i++)
        snprintf(hexadecimal + i * 2, 3, "%02x", digest[i]);
    if (strcmp(hexadecimal, expected)) {
        fprintf(stderr, "%s: got %s, expected %s\n", name, hexadecimal, expected);
        return 1;
    }
    return 0;
}

static int check_message(const char *name, const unsigned char *message,
                         unsigned int length, const char *expected)
{
    unsigned char digest[32];
    int failed;
    sha256(message, length, digest);
    failed = check_digest(name, digest, expected);

    /* Alternating chunks cross compression and padding boundaries. */
    sha256_ctx context;
    sha256_init(&context);
    for (unsigned int offset = 0; offset < length;) {
        unsigned int chunk = offset % 2 ? 65 : 63;
        if (chunk > length - offset)
            chunk = length - offset;
        sha256_update(&context, message + offset, chunk);
        offset += chunk;
    }
    sha256_final(&context, digest);
    return failed | check_digest(name, digest, expected);
}

int main(void)
{
    int failed = check_message("empty", (const unsigned char *)"", 0,
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    failed |= check_message("abc", (const unsigned char *)"abc", 3,
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    const unsigned char multi[] = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
    failed |= check_message("FIPS multi-block", multi, sizeof(multi) - 1,
        "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
    unsigned char *million = malloc(1000000);
    if (!million)
        return 2;
    memset(million, 'a', 1000000);
    failed |= check_message("million a", million, 1000000,
        "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0");
    free(million);

    /* Bitcoin genesis block header, in the wire byte order pools hash. */
    const char header_hex[] =
        "0100000000000000000000000000000000000000000000000000000000000000"
        "000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa"
        "4b1e5e4a29ab5f49ffff001d1dac2b7c";
    unsigned char header[80], digest[32], double_digest[32];
    for (unsigned int i = 0; i < sizeof(header); i++) {
        unsigned int byte;
        if (sscanf(header_hex + i * 2, "%2x", &byte) != 1)
            return 2;
        header[i] = (unsigned char)byte;
    }
    sha256(header, sizeof(header), digest);
    sha256(digest, sizeof(digest), double_digest);
    failed |= check_digest("genesis double SHA256", double_digest,
        "6fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000");
    if (!failed)
        puts("portable C SHA256: four FIPS vectors, incremental hashing and genesis double hash passed");
    return failed;
}
