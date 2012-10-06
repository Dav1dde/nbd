private {
    import nbd;

    import std.stdio;
}

void main() {
    auto nf = new NBTFile("hello_world.nbt");
    nf.read();

    writefln("%s", nf.value);
}