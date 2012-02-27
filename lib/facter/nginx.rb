Facter.add(:nginxversion) do
    setcode do
        pattern = %r{^\d{1,}\.\d{1,}\.\d{1,}$}
        unless defined?(@@nginxversion)
            @@nginxversion = Facter::Util::Resolution.exec('nginx -v 2>&1 | cut -d "/" -f 2')
        end

        if pattern.match(@@nginxversion)
            @@nginxversion
        else
            nil
        end
    end
end
