private {
    import nbd;

    import std.stdio;
    import std.file;
    import std.algorithm;
}

void main() {
    foreach(file; dirEntries(".", SpanMode.shallow).filter!(x => x.name.endsWith(".nbt"))) {
        writefln("\nFile: %s", file);
        auto nf = new NBTFile(file);

        writefln("%s\n", nf.value);

        nf.save(file ~ "_new");
    }

    foreach(file; dirEntries(".", SpanMode.shallow).filter!(x => x.name.endsWith(".nbt_new"))) {
        writefln("\nFile: %s", file);
        auto nf = new NBTFile(file);

        writefln("%s\n", nf.value);
    }
    
}