private {
    import nbd;

    import std.stdio;
}

void main() {
    foreach(file; ["hello_world.nbt", "bigtest.nbt"]) {
        writefln("\nFile: %s", file);
        auto nf = new NBTFile(file);

        writefln("%s\n", nf.value);
    }
}