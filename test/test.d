private {
    import nbd;

    import std.stdio;
}

void main() {
    auto nf = new NBTFile("hello_world.nbt");

    writefln("%s", nf.value);
}